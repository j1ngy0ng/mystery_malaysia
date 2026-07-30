-- Retire previously cached routine businesses and unqualified worship venues.
-- Manually curated destinations are intentionally unaffected.
update public.destinations
set
  active = false,
  source_metadata = source_metadata || jsonb_build_object(
    'deactivation_reason',
    'failed_logical_tourism_policy'
  ),
  updated_at = now()
where safety_status = 'automated_review'
  and (
    'Food' = any(categories)
    or primary_type in (
      'restaurant',
      'fast_food_restaurant',
      'cafe',
      'coffee_shop',
      'food_court',
      'meal_takeaway',
      'meal_delivery',
      'shopping_mall',
      'supermarket',
      'convenience_store',
      'apartment_building',
      'apartment_complex',
      'condominium_complex',
      'housing_complex'
    )
    or primary_type like '%\_restaurant' escape '\'
    or (
      primary_type in (
        'place_of_worship',
        'mosque',
        'church',
        'hindu_temple',
        'buddhist_temple',
        'synagogue',
        'shinto_shrine'
      )
      and not exists (
        select 1
        from jsonb_array_elements_text(
          case
            when jsonb_typeof(source_metadata -> 'google_types') = 'array'
              then source_metadata -> 'google_types'
            else '[]'::jsonb
          end
        ) as place_type(value)
        where place_type.value in (
          'tourist_attraction',
          'cultural_landmark',
          'historical_landmark',
          'historical_place',
          'monument',
          'museum'
        )
      )
    )
  );
