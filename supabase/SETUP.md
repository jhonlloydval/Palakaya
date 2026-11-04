# Cloud database setup (Supabase)

The app works fully offline without this. These steps turn on cloud sync.

1. Sign in at https://supabase.com.
   - **New organization**: name it after yourself (e.g. "JLV Projects"), not after this app.
     One organization holds many projects. Plan: **Free**.
   - **New project** inside it: name `palakaya`, click **Generate a password** (save it; the app does not need it),
     region **Southeast Asia (Singapore)**. Wait 1–2 minutes for it to finish setting up.
   - The free plan allows 2 active projects in total; unused ones auto-pause and can be resumed.
2. **SQL Editor → New query**: paste and **Run** each file, in this order (one query each):
   1. `supabase/schema.sql` (tables, security, marketplace and fair-price views)
   2. `supabase/004_buyers_offers.sql` (buyer accounts, verification, offers, demo payments)
   3. `supabase/006_catch_photos.sql` (catch photos on listings)
   4. `supabase/seed_demo.sql` (optional: demo accounts and a month of realistic data; see the README)

   Already ran `schema.sql` before `002`/`003`/`005` existed? Also run `002_market.sql`, `003_fair_prices.sql`
   and `005_regional_fair_prices.sql` (fair prices per province for the location picker on Fair Prices).
   Also run `006_catch_photos.sql` so catch photos upload and show on listings for buyers and other fishers.
   Copy a file to the clipboard from Terminal with, for example:
   `pbcopy < ~/GitHub/Palakaya/supabase/004_buyers_offers.sql`
3. **Authentication → Sign In / Providers → Email**: turn **off** "Confirm email".
   The app signs in with your mobile number mapped to a placeholder address, which cannot receive mail.
4. **Project Settings → API**: copy the **Project URL** and the **anon public** key.
   Never use the `service_role` key in the app.
5. Copy `supabase/Secrets.example.plist` to `Palakaya/Config/Secrets.plist` and paste in the two values.
   This file is git-ignored, so your key will not be pushed.
6. Run the app, register or log in, and log a catch.
   Check **Table Editor → catches**: the row should appear within a few seconds.

## Verifying a buyer
Check the buyer's business permit, cooperative registration or ID, then in **Table Editor → profiles**
find their row and set `verified` to `true`. Fishers see the Verified badge on that buyer's offers.
The app can never set this itself.

## What syncs
- Your profile, when you log in or register.
- Catches, listings and sales, right after you save them and when you tap the Wi-Fi button on Home.
- Records saved offline are kept on the phone and upload on the next successful sync.

## Privacy
- Row Level Security: each account can only read and write its own rows.
- `regional_catch_summary` gives BFAR/LGU-style totals by province, species and month,
  with no names, and hides any group with fewer than 5 catches.

## Known limits (prototype)
- Catches download after login, but edits made on two phones at the same time are not merged:
  the phone that uploads last wins.
- Advisor chat history stays on the phone; it is not synced.
- Payments are a demonstration: no payment provider is contacted and no money moves.

## AI Advisor (free)
Without this, the Advisor still answers offline with simple built-in rules.
Everything here is free: the Advisor runs as a Supabase Edge Function (free plan) and uses
Google Gemini's free tier (no credit card; daily limits apply).

Note: on Gemini's free tier Google may use requests to improve its models. The Advisor sends catch records and
municipality, never names, mobile numbers or passwords.

1. Get a key: https://aistudio.google.com/apikey → sign in with Google → **Create API key**.
2. Supabase → **Edge Functions** → **Secrets** → add `GEMINI_API_KEY` with that key.
   The key stays on the server; it is never put in the app.
3. Supabase → **Edge Functions** → **Deploy a new function** → **Via Editor**.
   Name it exactly `advisor`, replace the sample code with all of `supabase/functions/advisor/index.ts`, and click **Deploy**.
   Leave **Verify JWT** on, so only signed-in fishers can use it.
4. In the app, open **Advisor**, type a question and send. Answers use your own catches and current fair prices.
   If the free limit is reached, or there is no signal, the app answers with the offline rules instead.
