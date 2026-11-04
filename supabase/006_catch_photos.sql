-- Palakaya migration 006: catch photos on listings.
-- Run once in Supabase → SQL Editor, after 004_buyers_offers.sql. Safe to run again.

-- Public bucket for catch photos. Each fisher can only upload into a folder named after their own user id.
insert into storage.buckets (id, name, public)
values ('catch-photos', 'catch-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "Fishers upload their own catch photos" on storage.objects;
create policy "Fishers upload their own catch photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'catch-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- Replacing a photo (upsert) needs to see the existing file, so owners can also read their own folder.
drop policy if exists "Fishers read their own catch photos" on storage.objects;
create policy "Fishers read their own catch photos" on storage.objects
    for select to authenticated
    using (bucket_id = 'catch-photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Fishers replace their own catch photos" on storage.objects;
create policy "Fishers replace their own catch photos" on storage.objects
    for update to authenticated
    using (bucket_id = 'catch-photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Fishers delete their own catch photos" on storage.objects;
create policy "Fishers delete their own catch photos" on storage.objects
    for delete to authenticated
    using (bucket_id = 'catch-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- Where the photo of each catch is stored, if it has one.
alter table public.catches add column if not exists photo_url text;

-- Listings now include the photo.
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
    (select count(*) from public.offers o where o.catch_id = c.id and o.status = 'pending') as offer_count,
    c.photo_url
from public.catches c
join public.profiles p on p.id = c.owner_id
where c.status = 'listed'
  and c.price_per_kg is not null
  and c.owner_id <> auth.uid()
order by c.caught_at desc;

revoke all on public.market_listings from anon;
grant select on public.market_listings to authenticated;
