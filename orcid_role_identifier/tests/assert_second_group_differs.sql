/*
    A title's second group can never be its first.

    A guard rather than a discovery: dim_title_group's second_hits join
    already carries `s.second_title_group != r.title_group_resolved`, so this
    cannot fire unless that condition is removed or the mirror rules are
    rewritten. It exists because the mirror pair is the whole mechanism -
    teaching -> leadership and leadership -> teaching - and a title naming
    both jobs would otherwise be handed its own group back as the "second"
    one, and would look like it had two when it had one.
*/
select title_key, title, title_group, title_group_2
from {{ ref('dim_title_group') }}
where title_group_2 is not null
  and title_group_2 = title_group
