-- Palakaya migration 005: fair prices per province, so a fisher can compare their own area with others.
-- Run once in Supabase → SQL Editor, after schema.sql. Safe to run again.

-- Same rules as fair_prices (last 30 days, middle 50% of sold prices, at least 5 sales),
-- grouped by the seller's province so no single fisher's prices can be singled out.
create or replace view public.regional_fair_prices
with (security_invoker = false) as
select
    p.province,
    c.species,
    count(*) as sale_count,
    round(percentile_cont(0.25) within group (order by c.price_per_kg)::numeric) as low,
    round(percentile_cont(0.50) within group (order by c.price_per_kg)::numeric) as mid,
    round(percentile_cont(0.75) within group (order by c.price_per_kg)::numeric) as high,
    max(c.caught_at) as last_sale_at
from public.catches c
join public.profiles p on p.id = c.owner_id
where c.status = 'sold'
  and c.price_per_kg is not null
  and c.caught_at >= now() - interval '30 days'
  and p.province <> ''
group by p.province, c.species
having count(*) >= 5;

revoke all on public.regional_fair_prices from anon;
grant select on public.regional_fair_prices to authenticated;
