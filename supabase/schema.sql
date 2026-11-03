

-- Fair prices from real sales (same as migration 003_fair_prices.sql).
-- Per species, last 30 days of sales by all fishers: middle 50% of sold prices (p25–p75) and the median.
-- A species appears only after at least 5 sales, so one fisher's prices cannot be singled out.
create or replace view public.fair_prices
with (security_invoker = false) as
select
    species,
    count(*) as sale_count,
    round(percentile_cont(0.25) within group (order by price_per_kg)::numeric) as low,
    round(percentile_cont(0.50) within group (order by price_per_kg)::numeric) as mid,
    round(percentile_cont(0.75) within group (order by price_per_kg)::numeric) as high
from public.catches
where status = 'sold'
  and price_per_kg is not null
  and caught_at >= now() - interval '30 days'
group by species
having count(*) >= 5;

revoke all on public.fair_prices from anon;
grant select on public.fair_prices to authenticated;
