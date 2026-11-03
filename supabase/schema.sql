-- Palakaya cloud schema. Paste into Supabase Dashboard → SQL Editor → Run.
-- Each fisher can only read and write their own rows (Row Level Security).
-- Government-facing data is exposed only as aggregates with at least 5 catches per group.

create table if not exists public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    full_name text not null,
    mobile text not null unique,
    municipality text not null default '',
    province text not null default '',
    landing_site text not null default '',
    fisherfolk_id text not null default '',
    created_at timestamptz not null default now()
);

create table if not exists public.catches (
    id uuid primary key,
    owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
    species text not null,
    weight_kg numeric(8, 2) not null check (weight_kg > 0 and weight_kg <= 5000),
    fishing_ground text not null default '',
    caught_at timestamptz not null,
    status text not null check (status in ('available', 'listed', 'sold')),
    price_per_kg numeric(10, 2),
    sale_amount numeric(12, 2),
    buyer_name text,
    alignment_pct int,
    updated_at timestamptz not null default now()
);

create index if not exists catches_owner_idx on public.catches (owner_id);

-- Only signed-in users may reach these tables through the Data API; RLS below limits them to their own rows.
-- (Needed when "Automatically expose new tables" is off.)
revoke all on public.profiles, public.catches from anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.catches to authenticated;

alter table public.profiles enable row level security;
alter table public.catches enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
    for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "own catches" on public.catches;
create policy "own catches" on public.catches
    for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- Anonymized monthly summary for BFAR / LGU reporting. No names, no individual rows,
-- and any species-province-month group with fewer than 5 catches is hidden.
create or replace view public.regional_catch_summary
with (security_invoker = false) as
select
    p.province,
    c.species,
    date_trunc('month', c.caught_at)::date as month,
    count(*) as catch_count,
    round(sum(c.weight_kg), 1) as total_kg,
    round(percentile_cont(0.5) within group (order by c.price_per_kg)
          filter (where c.status = 'sold')::numeric, 2) as median_sold_price_per_kg
from public.catches c
join public.profiles p on p.id = c.owner_id
group by p.province, c.species, date_trunc('month', c.caught_at)
having count(*) >= 5;

revoke all on public.regional_catch_summary from anon;
grant select on public.regional_catch_summary to authenticated;

-- Shared marketplace (same as migration 002_market.sql).
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
