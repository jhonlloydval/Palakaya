-- Palakaya migration 002: shared marketplace.
-- Run once in Supabase → SQL Editor (after schema.sql). Safe to run again.

-- Listed catches from every fisher, so buyers and other fishers can see what is for sale.
-- Runs with the view owner's rights (bypasses RLS) but exposes only listing fields:
-- first name, landing site and the mobile number the fisher uses for buyer contact.
create or replace view public.market_listings
with (security_invoker = false) as
select
    c.id,
    c.species,
    c.weight_kg,
    c.price_per_kg,
    c.caught_at,
    split_part(p.full_name, ' ', 1) as seller_first_name,
    nullif(p.landing_site, '') as landing_site,
    nullif(p.municipality, '') as municipality,
    p.mobile as contact_mobile
from public.catches c
join public.profiles p on p.id = c.owner_id
where c.status = 'listed'
  and c.price_per_kg is not null
  and c.owner_id <> auth.uid()
order by c.caught_at desc;

revoke all on public.market_listings from anon;
grant select on public.market_listings to authenticated;
