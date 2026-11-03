# Cloud database setup (Supabase)

The app works fully offline without this. These steps turn on cloud sync.

1. Create a free project at https://supabase.com (region: Southeast Asia / Singapore).
2. **SQL Editor → New query**: paste `supabase/schema.sql` and click **Run**.
3. **Authentication → Sign In / Providers → Email**: turn **off** "Confirm email".
   The app signs in with your mobile number mapped to a placeholder address, which cannot receive mail.
4. **Project Settings → API**: copy the **Project URL** and the **anon public** key.
   Never use the `service_role` key in the app.
5. Copy `supabase/Secrets.example.plist` to `Palakaya/Config/Secrets.plist` and paste in the two values.
   This file is git-ignored, so your key will not be pushed.
6. Run the app, register or log in, and log a catch.
   Check **Table Editor → catches**: the row should appear within a few seconds.

## What syncs
- Your profile, when you log in or register.
- Catches, listings and sales, right after you save them and when you tap the Wi-Fi button on Home.
- Records saved offline are kept on the phone and upload on the next successful sync.

## Privacy
- Row Level Security: each account can only read and write its own rows.
- `regional_catch_summary` gives BFAR/LGU-style totals by province, species and month,
  with no names, and hides any group with fewer than 5 catches.

## Known limits (prototype)
- Sync is upload-only. Data entered on another phone does not download yet.
- Catches on the phone are not separated per account. Use one account per device.
