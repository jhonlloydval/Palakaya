-- Palakaya migration 004: buyer accounts, buyer verification, offers and demo payments.
-- Run once in Supabase → SQL Editor (after schema.sql). Safe to run again.

-- 1. Buyer accounts ---------------------------------------------------------------------------------
alter table public.profiles add column if not exists role text not null default 'fisher';
alter table public.profiles add column if not exists business_name text not null default '';
alter table public.profiles add column if not exists verified boolean not null default false;

do $$ begin
    alter table public.profiles add constraint profiles_role_check check (role in ('fisher', 'buyer'));
exception when duplicate_object then null; end $$;

-- Only an admin (the Supabase dashboard / SQL editor) can mark a buyer as verified.
-- A user editing their own profile through the app can never change it.
create or replace function public.keep_verified_flag()
returns trigger language plpgsql as $$
begin
    if auth.role() = 'authenticated' then
        new.verified := case when tg_op = 'INSERT' then false else old.verified end;
    end if;
    return new;
end $$;

drop trigger if exists profiles_keep_verified on public.profiles;
create trigger profiles_keep_verified before insert or update on public.profiles
for each row execute function public.keep_verified_flag();

-- 2. Offers: a buyer offers a price for a listed catch; the fisher accepts or declines;
--    the buyer then pays (demo payment). -------------------------------------------------------------
create table if not exists public.offers (
    id uuid primary key default gen_random_uuid(),
    catch_id uuid not null references public.catches (id) on delete cascade,
    buyer_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
    fisher_id uuid references auth.users (id) on delete cascade,
    price_per_kg numeric(10, 2) not null check (price_per_kg > 0),
    quantity_kg numeric(8, 2) not null check (quantity_kg > 0),
    message text not null default '',
    status text not null default 'pending'
        check (status in ('pending', 'accepted', 'declined', 'paid', 'cancelled')),
    payment_method text,
    payment_ref text,
    paid_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists offers_buyer_idx on public.offers (buyer_id);
create index if not exists offers_fisher_idx on public.offers (fisher_id);

-- Fill in the fisher from the catch, and allow only real status moves:
--   fisher: pending → accepted | declined          buyer: pending → cancelled, accepted → paid
create or replace function public.check_offer()
returns trigger language plpgsql security definer set search_path = public as $$
declare
    is_buyer boolean;
    catch_owner uuid;
    catch_status text;
begin
    if tg_op = 'INSERT' then
        select owner_id, status into catch_owner, catch_status from public.catches where id = new.catch_id;
        if catch_owner is null then raise exception 'Listing not found'; end if;
        if auth.role() = 'authenticated' then
            if catch_status <> 'listed' then raise exception 'This catch is no longer for sale'; end if;
            select role = 'buyer' into is_buyer from public.profiles where id = auth.uid();
            if not coalesce(is_buyer, false) then raise exception 'Only buyer accounts can make offers'; end if;
            new.buyer_id := auth.uid();
            new.status := 'pending';
            new.payment_method := null; new.payment_ref := null; new.paid_at := null;
        end if;
        new.fisher_id := catch_owner;
        return new;
    end if;

    -- UPDATE
    new.id := old.id; new.catch_id := old.catch_id; new.buyer_id := old.buyer_id; new.fisher_id := old.fisher_id;
    new.created_at := old.created_at;
    new.updated_at := now();
    if coalesce(auth.role(), '') <> 'authenticated' then return new; end if;  -- admin / seed scripts

    if auth.uid() = old.fisher_id
       and old.status = 'pending' and new.status in ('accepted', 'declined') then
        new.price_per_kg := old.price_per_kg; new.quantity_kg := old.quantity_kg;
        return new;
    end if;
    if auth.uid() = old.buyer_id and old.status = 'pending' and new.status = 'cancelled' then
        return new;
    end if;
    if auth.uid() = old.buyer_id and old.status = 'accepted' and new.status = 'paid'
       and new.payment_method is not null and new.payment_ref is not null then
        new.price_per_kg := old.price_per_kg; new.quantity_kg := old.quantity_kg;
        new.paid_at := now();
        return new;
    end if;
    raise exception 'This offer can no longer be changed that way';
end $$;

drop trigger if exists offers_check on public.offers;
create trigger offers_check before insert or update on public.offers
for each row execute function public.check_offer();

-- When a fisher sells the catch, any other offers still waiting on it are declined.
create or replace function public.decline_other_offers()
returns trigger language plpgsql security definer set search_path = public as $$
begin
    if new.status <> 'listed' and old.status = 'listed' then
        update public.offers set status = 'declined' where catch_id = new.id and status = 'pending';
    end if;
    return new;
end $$;

drop trigger if exists catches_decline_offers on public.catches;
create trigger catches_decline_offers after update of status on public.catches
for each row execute function public.decline_other_offers();

alter table public.offers enable row level security;

drop policy if exists "offers: parties read" on public.offers;
create policy "offers: parties read" on public.offers
    for select using (auth.uid() in (buyer_id, fisher_id));
drop policy if exists "offers: buyers create" on public.offers;
create policy "offers: buyers create" on public.offers
    for insert with check (auth.uid() = buyer_id);
drop policy if exists "offers: parties update" on public.offers;
create policy "offers: parties update" on public.offers
    for update using (auth.uid() in (buyer_id, fisher_id));

revoke all on public.offers from anon;
grant select, insert, update on public.offers to authenticated;

-- 3. Views the app reads -----------------------------------------------------------------------------
-- Every offer the signed-in user is part of, with the catch and both parties' public details.
create or replace view public.my_offers
with (security_invoker = false) as
select
    o.id, o.catch_id, o.status, o.price_per_kg, o.quantity_kg, o.message,
    o.payment_method, o.payment_ref, o.paid_at, o.created_at, o.updated_at,
    c.species,
    (o.buyer_id = auth.uid()) as i_am_buyer,
    coalesce(nullif(b.business_name, ''), b.full_name) as buyer_name,
    b.verified as buyer_verified,
    nullif(b.municipality, '') as buyer_municipality,
    b.mobile as buyer_mobile,
    (select count(*) from public.offers p where p.buyer_id = o.buyer_id and p.status = 'paid') as buyer_paid_count,
    split_part(f.full_name, ' ', 1) as fisher_first_name,
    nullif(f.landing_site, '') as fisher_landing_site,
    f.mobile as fisher_mobile
from public.offers o
join public.catches c on c.id = o.catch_id
join public.profiles b on b.id = o.buyer_id
join public.profiles f on f.id = o.fisher_id
where auth.uid() in (o.buyer_id, o.fisher_id)
order by o.created_at desc;

revoke all on public.my_offers from anon;
grant select on public.my_offers to authenticated;

-- Market listings now also show to buyers how many offers a listing already has.
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
    p.mobile as contact_mobile,
    (select count(*) from public.offers o where o.catch_id = c.id and o.status = 'pending') as offer_count
from public.catches c
join public.profiles p on p.id = c.owner_id
where c.status = 'listed'
  and c.price_per_kg is not null
  and c.owner_id <> auth.uid()
order by c.caught_at desc;

revoke all on public.market_listings from anon;
grant select on public.market_listings to authenticated;

-- The signed-in user's own profile (used to restore an account on a new phone).
create or replace view public.my_profile
with (security_invoker = true) as
select id, full_name, mobile, municipality, province, landing_site, fisherfolk_id, role, business_name, verified
from public.profiles
where id = auth.uid();

grant select on public.my_profile to authenticated;
