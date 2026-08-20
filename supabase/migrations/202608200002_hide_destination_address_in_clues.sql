-- Keep clues destination-specific without revealing the exact street address.
update public.destination_clues as clue
set
  title = 'Find this exact hidden stop',
  prompt = format(
    'Seek a %s in %s. Its official name has %s word%s and the initials “%s”. Follow the Hot & Cold signal and look for matching visitor signage.',
    replace(coalesce(nullif(destination.primary_type, ''), 'public local attraction'), '_', ' '),
    coalesce(nullif(destination.city, ''), nullif(destination.state, ''), 'your nearby area'),
    cardinality(regexp_split_to_array(trim(destination.name), '\s+')),
    case
      when cardinality(regexp_split_to_array(trim(destination.name), '\s+')) = 1 then ''
      else 's'
    end,
    (
      select string_agg(upper(left(word, 1)), ' • ' order by position)
      from unnest(regexp_split_to_array(trim(destination.name), '\s+'))
        with ordinality as name_word(word, position)
    )
  ),
  hint_text = case
    when cardinality(regexp_split_to_array(trim(destination.name), '\s+')) > 1
      then format(
        'The destination name has %s words and ends with “%s”.',
        cardinality(regexp_split_to_array(trim(destination.name), '\s+')),
        regexp_replace(trim(destination.name), '^.*\s', '')
      )
    else format(
      'The destination name has %s characters, starts with “%s” and ends with “%s”. Look for its official visitor sign nearby.',
      char_length(trim(destination.name)),
      upper(left(destination.name, 1)),
      upper(right(destination.name, 1))
    )
  end,
  ai_model = null,
  prompt_version = 'places-specific-no-address-v3',
  updated_at = now()
from public.destinations as destination
where clue.destination_id = destination.id;

-- Active and paused sessions copied their clue text when the mission started.
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
