#!/bin/bash
# Uploads the demo listing photos in supabase/demo-photos to the `catch-photos` bucket.
# Each photo is uploaded while signed in as its demo fisher, since fishers may only write to their own folder.
# Needs seed_demo.sql and 006_catch_photos.sql to have been run. Then run 007_demo_photos.sql.
# Usage, from the project folder:  bash supabase/upload_demo_photos.sh
set -euo pipefail
cd "$(dirname "$0")/.."

plist=Palakaya/Config/Secrets.plist
url=$(/usr/libexec/PlistBuddy -c "Print :SUPABASE_URL" "$plist")
key=$(/usr/libexec/PlistBuddy -c "Print :SUPABASE_ANON_KEY" "$plist")

# catch id, fisher mobile, fisher user id
photos="
a0000000-0000-4000-8000-000000000004 09172345678 d0000000-0000-4000-8000-000000000001
b0000000-0000-4000-8000-000000000201 09171110001 d0000000-0000-4000-8000-000000000002
b0000000-0000-4000-8000-000000000202 09171110002 d0000000-0000-4000-8000-000000000003
b0000000-0000-4000-8000-000000000203 09171110003 d0000000-0000-4000-8000-000000000004
b0000000-0000-4000-8000-000000000204 09171110001 d0000000-0000-4000-8000-000000000002
b0000000-0000-4000-8000-000000000205 09171110004 d0000000-0000-4000-8000-000000000005
"

echo "$photos" | while read -r catch mobile owner; do
    [ -z "$catch" ] && continue
    token=$(curl -s "$url/auth/v1/token?grant_type=password" -H "apikey: $key" -H "Content-Type: application/json" \
        -d "{\"email\":\"$mobile@palakaya.example.com\",\"password\":\"password\"}" \
        | python3 -c 'import sys,json; print(json.load(sys.stdin).get("access_token",""))')
    if [ -z "$token" ]; then echo "Could not sign in as $mobile (run seed_demo.sql first)"; exit 1; fi
    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$url/storage/v1/object/catch-photos/$owner/$catch.jpg" \
        -H "apikey: $key" -H "Authorization: Bearer $token" -H "Content-Type: image/jpeg" \
        --data-binary "@supabase/demo-photos/$catch.jpg")
    case "$status" in
        200) echo "$catch uploaded" ;;
        400|409) echo "$catch already uploaded (or not allowed: HTTP $status)" ;;
        *) echo "$catch failed: HTTP $status" ;;
    esac
done
echo "Done. Now run supabase/007_demo_photos.sql in the SQL Editor."
