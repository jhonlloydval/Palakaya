-- Palakaya demo data: accounts, a month of catches and sales, live listings, offers and payments.
-- Run in Supabase → SQL Editor AFTER schema.sql and 004_buyers_offers.sql. Safe to run again:
-- accounts are reused if they exist, and every row has a fixed id.
-- All demo accounts use the password:  password
-- Remove everything later with the "clean up" block at the bottom of this file.

-- Helpers (dropped at the end) -----------------------------------------------------------------------
create or replace function public.demo_user(p_id uuid, p_mobile text, p_name text, p_municipality text,
    p_province text, p_landing text, p_role text, p_business text, p_verified boolean)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare
    v_email text := p_mobile || '@palakaya.example.com';
    v_id uuid;
begin
    select id into v_id from auth.users where email = v_email;
    if v_id is null then
        v_id := p_id;
        insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, email_change, email_change_token_new, recovery_token)
        values ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated', v_email,
            extensions.crypt('password', extensions.gen_salt('bf')), now(),
            '{"provider":"email","providers":["email"]}', '{}', now() - interval '45 days', now(),
            '', '', '', '');
        insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
        values (gen_random_uuid(), v_id, v_id::text,
            jsonb_build_object('sub', v_id::text, 'email', v_email, 'email_verified', true),
            'email', now(), now() - interval '45 days', now());
    end if;
    insert into public.profiles (id, full_name, mobile, municipality, province, landing_site, role, business_name, verified, created_at)
    values (v_id, p_name, p_mobile, p_municipality, p_province, p_landing, p_role, p_business, p_verified, now() - interval '45 days')
    on conflict (id) do update set full_name = excluded.full_name, municipality = excluded.municipality,
        province = excluded.province, landing_site = excluded.landing_site, role = excluded.role,
        business_name = excluded.business_name, verified = excluded.verified;
    return v_id;
end $$;

create or replace function public.demo_catch(p_id uuid, p_owner uuid, p_species text, p_kg numeric, p_ground text,
    p_days_ago int, p_hour int, p_minute int, p_status text, p_price numeric, p_buyer text)
returns void language plpgsql security definer set search_path = public as $$
declare
    v_mid numeric := case p_species when 'Galunggong' then 192 when 'Tamban' then 160 when 'Tulingan' then 210
        when 'Bisugo' then 202 when 'Bangus' then 178 when 'Alumahan' then 170 end;
    v_sold boolean := p_status = 'sold';
begin
    insert into public.catches (id, owner_id, species, weight_kg, fishing_ground, caught_at, status,
        price_per_kg, sale_amount, buyer_name, alignment_pct)
    values (p_id, p_owner, p_species, p_kg, p_ground,
        date_trunc('day', now() at time zone 'Asia/Manila') at time zone 'Asia/Manila'
            - make_interval(days => p_days_ago) + make_interval(hours => p_hour, mins => p_minute),
        p_status, p_price,
        case when v_sold then round(p_price * p_kg) end,
        case when v_sold then p_buyer end,
        case when v_sold and v_mid is not null then floor(p_price / v_mid * 100)::int end)
    on conflict (id) do update set owner_id = excluded.owner_id, species = excluded.species,
        weight_kg = excluded.weight_kg, fishing_ground = excluded.fishing_ground, caught_at = excluded.caught_at,
        status = excluded.status, price_per_kg = excluded.price_per_kg, sale_amount = excluded.sale_amount,
        buyer_name = excluded.buyer_name, alignment_pct = excluded.alignment_pct, updated_at = now();
end $$;

create or replace function public.demo_offer(p_id uuid, p_catch uuid, p_buyer uuid, p_price numeric, p_kg numeric,
    p_message text, p_status text, p_method text, p_ref text, p_hours_ago int)
returns void language plpgsql security definer set search_path = public as $$
begin
    insert into public.offers (id, catch_id, buyer_id, price_per_kg, quantity_kg, message, status,
        payment_method, payment_ref, paid_at, created_at, updated_at)
    values (p_id, p_catch, p_buyer, p_price, p_kg, p_message, p_status, p_method, p_ref,
        case when p_status = 'paid' then now() - make_interval(hours => greatest(p_hours_ago - 2, 0)) end,
        now() - make_interval(hours => p_hours_ago), now() - make_interval(hours => greatest(p_hours_ago - 1, 0)))
    on conflict (id) do nothing;
end $$;

-- Data -----------------------------------------------------------------------------------------------
do $$
declare
    -- Fishers
    jose uuid := public.demo_user('d0000000-0000-4000-8000-000000000001', '09172345678', 'Mang Jose Dela Cruz',
        'Bauan', 'Batangas, CALABARZON', 'Sabang Landing Site', 'fisher', '', false);
    roberto uuid := public.demo_user('d0000000-0000-4000-8000-000000000002', '09171110001', 'Roberto Mendoza',
        'Batangas City', 'Batangas, CALABARZON', 'Batangas City Fish Port', 'fisher', '', false);
    fely uuid := public.demo_user('d0000000-0000-4000-8000-000000000003', '09171110002', 'Felicidad Reyes',
        'Mabini', 'Batangas, CALABARZON', 'Anilao Landing Site', 'fisher', '', false);
    dindo uuid := public.demo_user('d0000000-0000-4000-8000-000000000004', '09171110003', 'Dindo Garcia',
        'Mabini', 'Batangas, CALABARZON', 'Mabini Fish Landing', 'fisher', '', false);
    rosario uuid := public.demo_user('d0000000-0000-4000-8000-000000000005', '09171110004', 'Rosario Aguilar',
        'Lobo', 'Batangas, CALABARZON', 'Lobo Fish Landing', 'fisher', '', false);
    -- Buyers
    liza uuid := public.demo_user('d0000000-0000-4000-8000-000000000011', '09181230001', 'Liza Santos',
        'Batangas City', 'Batangas, CALABARZON', '', 'buyer', 'Liza''s Seafood Stall', true);
    coastal uuid := public.demo_user('d0000000-0000-4000-8000-000000000012', '09181230002', 'Ramon Villanueva',
        'Bauan', 'Batangas, CALABARZON', '', 'buyer', 'Coastal Fresh Trading Cooperative', true);
    bayfish uuid := public.demo_user('d0000000-0000-4000-8000-000000000013', '09181230003', 'Jun Castillo',
        'Batangas City', 'Batangas, CALABARZON', '', 'buyer', 'Bay Fish Traders', false);
    mila uuid := public.demo_user('d0000000-0000-4000-8000-000000000014', '09181230004', 'Mila Torres',
        'Bauan', 'Batangas, CALABARZON', '', 'buyer', 'Ate Mila''s Carinderia', true);
begin
    -- Mang Jose's catches (same ids as the app's on-phone demo data)
    perform public.demo_catch('a0000000-0000-4000-8000-000000000004', jose, 'Tulingan', 18.0, 'Batangas Bay', 0, 6, 5, 'listed', 205, null);
    perform public.demo_catch('a0000000-0000-4000-8000-000000000002', jose, 'Bisugo', 6.4, 'Batangas Bay', 0, 6, 20, 'available', null, null);
    perform public.demo_catch('a0000000-0000-4000-8000-000000000003', jose, 'Alumahan', 10.2, 'Sabang Fishing Ground', 0, 6, 50, 'available', null, null);
    perform public.demo_catch('a0000000-0000-4000-8000-000000000001', jose, 'Tamban', 8.0, 'Sabang Fishing Ground', 1, 7, 10, 'sold', 160, 'Aling Nena''s Talipapa');
    perform public.demo_catch('a0000000-0000-4000-8000-000000000005', jose, 'Galunggong', 12.0, 'Sabang Fishing Ground', 3, 5, 40, 'sold', 190, 'Liza''s Seafood Stall');
    perform public.demo_catch('a0000000-0000-4000-8000-000000000006', jose, 'Tulingan', 15.0, 'Batangas Bay', 6, 6, 15, 'sold', 208, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('a0000000-0000-4000-8000-000000000007', jose, 'Galunggong', 10.0, 'Sabang Fishing Ground', 10, 5, 55, 'sold', 185, 'Ate Mila''s Carinderia');
    perform public.demo_catch('a0000000-0000-4000-8000-000000000008', jose, 'Tamban', 9.0, 'Sabang Fishing Ground', 14, 6, 30, 'sold', 155, 'Bay Fish Traders');
    perform public.demo_catch('a0000000-0000-4000-8000-000000000009', jose, 'Bisugo', 7.0, 'Batangas Bay', 20, 6, 10, 'sold', 200, 'Liza''s Seafood Stall');

    -- Other fishers' sales this month (these make the fair prices come from real sales)
    perform public.demo_catch('b0000000-0000-4000-8000-000000000101', roberto, 'Galunggong', 14.0, 'Verde Island Passage', 2, 5, 30, 'sold', 196, 'Liza''s Seafood Stall');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000102', roberto, 'Galunggong', 11.5, 'Verde Island Passage', 8, 5, 45, 'sold', 188, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000103', dindo, 'Galunggong', 9.0, 'Balayan Bay', 12, 6, 0, 'sold', 182, 'Ate Mila''s Carinderia');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000104', rosario, 'Galunggong', 13.0, 'Lobo Coast', 17, 5, 20, 'sold', 200, 'Liza''s Seafood Stall');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000105', fely, 'Tamban', 16.0, 'Anilao Reef', 4, 6, 10, 'sold', 158, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000106', rosario, 'Tamban', 12.0, 'Lobo Coast', 9, 6, 40, 'sold', 165, 'Ate Mila''s Carinderia');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000107', dindo, 'Tamban', 18.0, 'Balayan Bay', 16, 5, 50, 'sold', 150, 'Bay Fish Traders');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000108', dindo, 'Tulingan', 22.0, 'Balayan Bay', 3, 5, 15, 'sold', 212, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000109', roberto, 'Tulingan', 17.0, 'Verde Island Passage', 7, 5, 5, 'sold', 205, 'Liza''s Seafood Stall');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000110', fely, 'Tulingan', 12.5, 'Anilao Reef', 13, 6, 25, 'sold', 200, 'Ate Mila''s Carinderia');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000111', rosario, 'Tulingan', 19.0, 'Lobo Coast', 22, 5, 35, 'sold', 214, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000112', fely, 'Bisugo', 8.0, 'Anilao Reef', 2, 6, 45, 'sold', 205, 'Liza''s Seafood Stall');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000113', roberto, 'Bisugo', 6.5, 'Verde Island Passage', 11, 6, 0, 'sold', 195, 'Ate Mila''s Carinderia');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000114', dindo, 'Bisugo', 9.5, 'Balayan Bay', 18, 5, 40, 'sold', 210, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000115', rosario, 'Bisugo', 7.0, 'Lobo Coast', 25, 6, 5, 'sold', 192, 'Bay Fish Traders');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000116', fely, 'Alumahan', 10.0, 'Anilao Reef', 1, 6, 30, 'sold', 172, 'Ate Mila''s Carinderia');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000117', roberto, 'Alumahan', 12.0, 'Verde Island Passage', 5, 5, 50, 'sold', 168, 'Liza''s Seafood Stall');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000118', dindo, 'Alumahan', 8.5, 'Balayan Bay', 9, 6, 15, 'sold', 175, 'Coastal Fresh Trading Cooperative');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000119', rosario, 'Alumahan', 11.0, 'Lobo Coast', 15, 5, 25, 'sold', 160, 'Bay Fish Traders');
    perform public.demo_catch('b0000000-0000-4000-8000-000000000120', fely, 'Alumahan', 9.0, 'Anilao Reef', 24, 6, 50, 'sold', 178, 'Ate Mila''s Carinderia');

    -- Fresh listings in the market right now
    perform public.demo_catch('b0000000-0000-4000-8000-000000000201', roberto, 'Galunggong', 9.0, 'Verde Island Passage', 0, 5, 20, 'listed', 195, null);
    perform public.demo_catch('b0000000-0000-4000-8000-000000000202', fely, 'Alumahan', 11.0, 'Anilao Reef', 0, 6, 10, 'listed', 172, null);
    perform public.demo_catch('b0000000-0000-4000-8000-000000000203', dindo, 'Tulingan', 20.0, 'Balayan Bay', 1, 5, 45, 'listed', 210, null);
    perform public.demo_catch('b0000000-0000-4000-8000-000000000204', roberto, 'Bisugo', 7.5, 'Verde Island Passage', 0, 6, 35, 'listed', 205, null);
    perform public.demo_catch('b0000000-0000-4000-8000-000000000205', rosario, 'Tamban', 14.0, 'Lobo Coast', 0, 5, 55, 'listed', 158, null);

    -- Paid purchases (history, receipts and buyer track records)
    perform public.demo_offer('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000005', liza, 190, 12.0, 'Pickup sa Sabang 2 PM.', 'paid', 'GCash', '5011247836512', 74);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000006', coastal, 208, 15.0, '', 'paid', 'LandBank', 'LBP4820019375', 146);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000007', mila, 185, 10.0, 'Para sa carinderia bukas.', 'paid', 'Maya', '730184562901', 242);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000008', bayfish, 155, 9.0, '', 'paid', 'GCash', '5009836127745', 338);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000009', liza, 200, 7.0, '', 'paid', 'GCash', '5007419920358', 482);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000101', liza, 196, 14.0, '', 'paid', 'Maya', '730192846615', 50);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000108', coastal, 212, 22.0, '', 'paid', 'LandBank', 'LBP4820144630', 74);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000112', liza, 205, 8.0, '', 'paid', 'GCash', '5012638840173', 50);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000009', 'b0000000-0000-4000-8000-000000000116', mila, 172, 10.0, '', 'paid', 'GCash', '5013372205864', 26);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000010', 'b0000000-0000-4000-8000-000000000105', coastal, 158, 16.0, '', 'paid', 'LandBank', 'LBP4820207718', 98);

    -- Offers waiting on Mang Jose's Tulingan (log in as the fisher to accept one)
    perform public.demo_offer('c0000000-0000-4000-8000-000000000101', 'a0000000-0000-4000-8000-000000000004', coastal, 207, 18.0, 'For our members'' processing. We can pick up today before 3 PM.', 'pending', null, null, 2);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000102', 'a0000000-0000-4000-8000-000000000004', liza, 200, 18.0, 'Kukunin ko lahat, may dala akong yelo. Pickup 3 PM sa Sabang.', 'pending', null, null, 1);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000103', 'a0000000-0000-4000-8000-000000000004', bayfish, 180, 18.0, 'Cash agad, kunin ko na ngayon.', 'pending', null, null, 1);

    -- Liza's offers: one accepted and ready to pay (log in as Liza to try the demo payment)
    perform public.demo_offer('c0000000-0000-4000-8000-000000000201', 'b0000000-0000-4000-8000-000000000201', liza, 192, 9.0, 'Pickup 10 AM sa fish port.', 'accepted', null, null, 3);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000202', 'b0000000-0000-4000-8000-000000000203', liza, 206, 10.0, 'Kalahati lang po muna.', 'pending', null, null, 5);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000203', 'b0000000-0000-4000-8000-000000000102', liza, 175, 11.5, '', 'declined', null, null, 196);

    -- Other buyers' offers on live listings
    perform public.demo_offer('c0000000-0000-4000-8000-000000000301', 'b0000000-0000-4000-8000-000000000202', coastal, 170, 11.0, '', 'pending', null, null, 2);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000302', 'b0000000-0000-4000-8000-000000000203', mila, 205, 8.0, '', 'pending', null, null, 4);
    perform public.demo_offer('c0000000-0000-4000-8000-000000000303', 'b0000000-0000-4000-8000-000000000205', bayfish, 150, 14.0, '', 'pending', null, null, 1);
end $$;

drop function public.demo_user(uuid, text, text, text, text, text, text, text, boolean);
drop function public.demo_catch(uuid, uuid, text, numeric, text, int, int, int, text, numeric, text);
drop function public.demo_offer(uuid, uuid, uuid, numeric, numeric, text, text, text, text, int);

-- Check: should list 9 accounts, about 34 catches and 19 offers.
select
    (select count(*) from public.profiles where mobile in ('09172345678','09171110001','09171110002','09171110003',
        '09171110004','09181230001','09181230002','09181230003','09181230004')) as demo_accounts,
    (select count(*) from public.catches) as catches,
    (select count(*) from public.offers) as offers,
    (select string_agg(species || ' ₱' || low || '–' || high || ' (' || sale_count || ' sales)', ', ')
       from public.fair_prices) as live_fair_prices;

/* Clean up (only when you want the demo data gone): run this block separately.
delete from auth.users where email in (
  '09172345678@palakaya.example.com','09171110001@palakaya.example.com','09171110002@palakaya.example.com',
  '09171110003@palakaya.example.com','09171110004@palakaya.example.com','09181230001@palakaya.example.com',
  '09181230002@palakaya.example.com','09181230003@palakaya.example.com','09181230004@palakaya.example.com');
*/
