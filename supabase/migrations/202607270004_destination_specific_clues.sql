-- Replace the generic navigation instruction with a destination-specific clue.
update public.destination_clues as clue
set
  title = 'Find this exact hidden stop',
  prompt = format(
    'Find the %s in %s whose name starts with “%s”. %s',
    replace(coalesce(nullif(destination.primary_type, ''), 'public local attraction'), '_', ' '),
    coalesce(nullif(destination.city, ''), nullif(destination.state, ''), 'your nearby area'),
    upper(left(destination.name, 1)),
    case
      when nullif(destination.formatted_address, '') is not null
        then 'Google lists it at ' || destination.formatted_address || '.'
      else 'Look for its official entrance and matching place signage.'
    end
  ),
  hint_text = case
    when cardinality(regexp_split_to_array(trim(destination.name), '\s+')) > 1
      then format(
        'The destination name has %s words and ends with “%s”.',
        cardinality(regexp_split_to_array(trim(destination.name), '\s+')),
        regexp_replace(trim(destination.name), '^.*\s', '')
      )
    else format(
      'The destination name has %s characters and starts with “%s”.',
      char_length(trim(destination.name)),
      upper(left(destination.name, 1))
    )
  end,
  ai_model = null,
  prompt_version = 'places-specific-location-v2',
  updated_at = now()
from public.destinations as destination
where clue.destination_id = destination.id;

-- Existing active or paused sessions copied the old prompt when they started.
update public.mission_clue_reveals as reveal
set
  title = clue.title,
  prompt = clue.prompt
from public.mission_stage_secrets as secret
join public.destination_clues as clue
  on clue.destination_id = secret.destination_id
join public.mission_stages as stage
  on stage.id = secret.stage_id
where reveal.stage_id = secret.stage_id
  and stage.status in ('locked', 'active');
