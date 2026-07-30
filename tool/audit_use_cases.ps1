$ErrorActionPreference = 'Stop'

$config = Get-Content '.env.local.json' -Raw | ConvertFrom-Json
$baseUrl = $config.SUPABASE_URL.TrimEnd('/')
$anon = $config.SUPABASE_PUBLISHABLE_KEY
$projectRef = (Get-Content 'supabase/.temp/project-ref' -Raw).Trim()
$keys = npx.cmd supabase projects api-keys --project-ref $projectRef -o json |
    ConvertFrom-Json
$service = ($keys | Where-Object { $_.id -eq 'service_role' }).api_key
$adminHeaders = @{
    apikey = $service
    Authorization = "Bearer $service"
    'Content-Type' = 'application/json'
}

function Invoke-Json {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers,
        [object]$Body
    )
    try {
        $arguments = @{
            Method = $Method
            Uri = $Uri
            Headers = $Headers
        }
        if ($null -ne $Body) {
            $arguments.Body = $Body | ConvertTo-Json -Depth 12 -Compress
        }
        Invoke-RestMethod @arguments
    }
    catch {
        if ($_.Exception.Response) {
            $reader = [System.IO.StreamReader]::new(
                $_.Exception.Response.GetResponseStream()
            )
            throw "$($_.Exception.Message) $($reader.ReadToEnd())"
        }
        throw
    }
}

function New-AuditUser {
    param([string]$Label)
    $email = "use-case-$Label-$([guid]::NewGuid().ToString('N'))@example.com"
    $password = "Audit!$([guid]::NewGuid().ToString('N'))"
    $created = Invoke-Json Post "$baseUrl/auth/v1/admin/users" $adminHeaders @{
        email = $email
        password = $password
        email_confirm = $true
        user_metadata = @{
            username = "audit_$Label$([guid]::NewGuid().ToString('N').Substring(0, 8))"
            display_name = "Audit $Label"
            gender = 'prefer_not_to_say'
            date_of_birth = '2000-01-01'
        }
    }
    $token = Invoke-Json Post "$baseUrl/auth/v1/token?grant_type=password" @{
        apikey = $anon
        'Content-Type' = 'application/json'
    } @{
        email = $email
        password = $password
    }
    [pscustomobject]@{
        Id = $created.id
        Email = $email
        Headers = @{
            apikey = $anon
            Authorization = "Bearer $($token.access_token)"
            'Content-Type' = 'application/json'
        }
    }
}

function Invoke-Function {
    param([string]$Name, [hashtable]$Headers, [hashtable]$Body)
    Invoke-Json Post "$baseUrl/functions/v1/$Name" $Headers $Body
}

$hostUser = $null
$memberUser = $null
$sessionId = $null
$requestId = $null

try {
    $hostUser = New-AuditUser 'host'
    $memberUser = New-AuditUser 'member'

    $profile = Invoke-Json Get (
        "$baseUrl/rest/v1/profiles?select=username,gender,date_of_birth&id=eq.$($hostUser.Id)"
    ) $adminHeaders $null

    $generated = Invoke-Function 'generate-mission' $hostUser.Headers @{
        origin_latitude = 3.1390
        origin_longitude = 101.6869
        available_minutes = 360
        budget_myr = 250
        maximum_distance_km = 25
        categories = @('Culture', 'History', 'Nature')
        group_type = 'solo'
    }
    $requestId = $generated.request_id
    $recommendations = @($generated.recommendations)
    if ($recommendations.Count -ne 3) {
        throw "Expected three mission lists, received $($recommendations.Count)."
    }
    if (@($recommendations | Where-Object { $_.stops -ne 3 }).Count -gt 0) {
        throw 'Every generated mission must contain three stops.'
    }

    $regenerated = Invoke-Function 'regenerate-stop' $hostUser.Headers @{
        recommendation_id = [string]$recommendations[0].id
        stop_number = 2
    }

    $shared = Invoke-Function 'start-mission' $hostUser.Headers @{
        recommendation_id = [string]$recommendations[0].id
        mode = 'collaborative'
    }
    $sessionId = $shared.session_id
    $invite = Invoke-Function 'shared-mission' $hostUser.Headers @{
        action = 'invite'
        session_id = $sessionId
        email = $memberUser.Email
    }
    $memberOverview = Invoke-Function 'shared-mission' $memberUser.Headers @{
        action = 'overview'
    }
    $memberInvitation = @($memberOverview.invitations)[0]
    Invoke-Function 'shared-mission' $memberUser.Headers @{
        action = 'respond'
        invitation_id = $memberInvitation.id
        response = 'accepted'
    } | Out-Null
    Invoke-Function 'shared-mission' $hostUser.Headers @{
        action = 'remove'
        session_id = $sessionId
        member_id = $memberUser.Id
    } | Out-Null
    $repeatInvite = Invoke-Function 'shared-mission' $hostUser.Headers @{
        action = 'invite'
        session_id = $sessionId
        email = $memberUser.Email
    }
    $memberOverview = Invoke-Function 'shared-mission' $memberUser.Headers @{
        action = 'overview'
    }
    $memberInvitation = @($memberOverview.invitations)[0]
    Invoke-Function 'shared-mission' $memberUser.Headers @{
        action = 'respond'
        invitation_id = $memberInvitation.id
        response = 'accepted'
    } | Out-Null
    $externalInvite = $null
    if (-not [string]::IsNullOrWhiteSpace($env:MYSTERY_AUDIT_INVITE_EMAIL)) {
        $externalInvite = Invoke-Function 'shared-mission' $hostUser.Headers @{
            action = 'invite'
            session_id = $sessionId
            email = $env:MYSTERY_AUDIT_INVITE_EMAIL
        }
    }
    Invoke-Function 'shared-mission' $hostUser.Headers @{
        action = 'ready'
        session_id = $sessionId
        ready = $true
    } | Out-Null
    Invoke-Function 'shared-mission' $memberUser.Headers @{
        action = 'ready'
        session_id = $sessionId
        ready = $true
    } | Out-Null
    Invoke-Function 'shared-mission' $hostUser.Headers @{
        action = 'start'
        session_id = $sessionId
    } | Out-Null

    $firstStage = @(
        Invoke-Json Get (
            "$baseUrl/rest/v1/mission_stages?select=id&session_id=eq.$sessionId&stage_number=eq.1"
        ) $adminHeaders $null
    )[0]
    $firstReveal = @(
        Invoke-Json Get (
            "$baseUrl/rest/v1/mission_clue_reveals?select=prompt&stage_id=eq.$($firstStage.id)"
        ) $adminHeaders $null
    )[0]
    $specificClue = $firstReveal.prompt.Length -gt 80 -and
        $firstReveal.prompt -notlike 'Use the clue to explore*'

    $hint = Invoke-Function 'mission-control' $hostUser.Headers @{
        action = 'hint'
        session_id = $sessionId
    }
    $hintAgain = Invoke-Function 'mission-control' $hostUser.Headers @{
        action = 'hint'
        session_id = $sessionId
    }
    Invoke-Function 'mission-control' $hostUser.Headers @{
        action = 'pause'
        session_id = $sessionId
    } | Out-Null
    Invoke-Function 'mission-control' $hostUser.Headers @{
        action = 'resume'
        session_id = $sessionId
    } | Out-Null

    $firstWaited = $false
    $guideComplete = $true
    for ($stageNumber = 1; $stageNumber -le 3; $stageNumber++) {
        $stage = @(
            Invoke-Json Get (
                "$baseUrl/rest/v1/mission_stages?select=id&session_id=eq.$sessionId&stage_number=eq.$stageNumber"
            ) $adminHeaders $null
        )[0]
        $secret = @(
            Invoke-Json Get (
                "$baseUrl/rest/v1/mission_stage_secrets?select=arrival_latitude,arrival_longitude&stage_id=eq.$($stage.id)"
            ) $adminHeaders $null
        )[0]
        $proximity = Invoke-Function 'mission-control' $hostUser.Headers @{
            action = 'proximity'
            session_id = $sessionId
            latitude = [double]$secret.arrival_latitude
            longitude = [double]$secret.arrival_longitude
            accuracy_metres = 5
        }
        if ($proximity.level -ne 'reached') {
            throw "Exact stage location did not produce reached proximity."
        }
        $hostArrival = Invoke-Function 'confirm-arrival' $hostUser.Headers @{
            session_id = $sessionId
            latitude = [double]$secret.arrival_latitude
            longitude = [double]$secret.arrival_longitude
            accuracy_metres = 5
        }
        if ($stageNumber -eq 1) {
            $firstWaited = $hostArrival.waiting_for_members -eq $true
        }
        $guideComplete = $guideComplete -and
            @($hostArrival.destination.facts).Count -gt 0 -and
            @($hostArrival.destination.visitor_information.cultural_etiquette).Count -gt 0 -and
            @($hostArrival.destination.visitor_information.safety_notes).Count -gt 0

        Invoke-Function 'confirm-arrival' $memberUser.Headers @{
            session_id = $sessionId
            latitude = [double]$secret.arrival_latitude
            longitude = [double]$secret.arrival_longitude
            accuracy_metres = 5
        } | Out-Null
    }

    $passport = Invoke-Function 'passport-diary' $hostUser.Headers @{
        action = 'dashboard'
    }
    $diary = Invoke-Function 'passport-diary' $hostUser.Headers @{
        action = 'generate_diary'
        session_id = $sessionId
        reflection = 'I loved uncovering the cultural details with my travel companion and learning respectfully at every stop.'
    }
    if ($diary.generated) {
        Invoke-Function 'passport-diary' $hostUser.Headers @{
            action = 'save_diary'
            session_id = $sessionId
            title = $diary.title
            content = $diary.content
        } | Out-Null
    }
    $reflection = Invoke-Function 'shared-mission' $memberUser.Headers @{
        action = 'reflection'
        session_id = $sessionId
        reflection = 'A memorable shared mystery journey across three verified destinations.'
    }

    if (@($passport.stamps).Count -ne 3) {
        throw "Expected three verified stamps, received $(@($passport.stamps).Count)."
    }
    if ($passport.stats.completed_missions -ne 1) {
        throw 'The completed mission was not included in progression.'
    }
    if (-not $diary.generated) {
        throw 'The verified AI diary was not generated.'
    }
    if (-not $firstWaited) {
        throw 'The shared stage advanced before every member arrived.'
    }
    if (-not $guideComplete) {
        throw 'At least one arrival guide was missing facts, cultural etiquette, or safety guidance.'
    }
    if (-not $specificClue) {
        throw 'The first destination still used a generic clue.'
    }
    if (-not $repeatInvite.registered) {
        throw 'A removed registered member could not be invited again.'
    }
    if ($null -ne $externalInvite -and -not $externalInvite.email_sent) {
        throw 'The unregistered traveller did not receive an invitation email.'
    }

    $auditReport = [pscustomobject]@{
        status = 'passed'
        profile_metadata = @($profile).Count -eq 1
        mission_lists = $recommendations.Count
        stops_per_mission = 3
        stop_regenerated = $regenerated.recommendation.id -eq $recommendations[0].id
        destination_specific_clue = $specificClue
        registered_invitation = $invite.registered
        member_removed_and_reinvited = $repeatInvite.registered
        unregistered_email_invitation = if ($null -eq $externalInvite) {
            'skipped; set MYSTERY_AUDIT_INVITE_EMAIL to exercise email delivery'
        } else {
            [bool]$externalInvite.email_sent
        }
        one_hint_only = $hintAgain.already_used
        group_waited_for_all = $firstWaited
        arrival_guide_complete = $guideComplete
        stamps = @($passport.stamps).Count
        completed_missions = $passport.stats.completed_missions
        badges = @($passport.badges).Count
        diary_generated = $diary.generated
        reflection_saved = [bool]$reflection.message
    } | ConvertTo-Json
    [Console]::WriteLine($auditReport)
}
finally {
    if ($hostUser) {
        try {
            Invoke-Json Delete "$baseUrl/auth/v1/admin/users/$($hostUser.Id)" $adminHeaders $null |
                Out-Null
        }
        catch {}
    }
    if ($memberUser) {
        try {
            Invoke-Json Delete "$baseUrl/auth/v1/admin/users/$($memberUser.Id)" $adminHeaders $null |
                Out-Null
        }
        catch {}
    }
    if ($sessionId) {
        try {
            Invoke-Json Delete "$baseUrl/rest/v1/mission_sessions?id=eq.$sessionId" $adminHeaders $null |
                Out-Null
        }
        catch {}
    }
    if ($requestId) {
        try {
            Invoke-Json Delete "$baseUrl/rest/v1/mission_requests?id=eq.$requestId" $adminHeaders $null |
                Out-Null
        }
        catch {}
    }
}
