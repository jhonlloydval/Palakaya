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
