-- Palakaya migration 007: photos on the demo listings.
-- Run after seed_demo.sql and after uploading the photos with supabase/upload_demo_photos.sh. Safe to run again.
-- Each photo lives in its fisher's folder of the public `catch-photos` bucket; the app turns the path into a link.

-- Missing from the first version of 006: replacing a photo (upsert) needs owners to read their own folder.
drop policy if exists "Fishers read their own catch photos" on storage.objects;
create policy "Fishers read their own catch photos" on storage.objects
    for select to authenticated
    using (bucket_id = 'catch-photos' and (storage.foldername(name))[1] = auth.uid()::text);

update public.catches c set photo_url = p.path
from (values
    ('a0000000-0000-4000-8000-000000000004'::uuid, 'd0000000-0000-4000-8000-000000000001/a0000000-0000-4000-8000-000000000004.jpg'),
    ('b0000000-0000-4000-8000-000000000201'::uuid, 'd0000000-0000-4000-8000-000000000002/b0000000-0000-4000-8000-000000000201.jpg'),
    ('b0000000-0000-4000-8000-000000000202'::uuid, 'd0000000-0000-4000-8000-000000000003/b0000000-0000-4000-8000-000000000202.jpg'),
    ('b0000000-0000-4000-8000-000000000203'::uuid, 'd0000000-0000-4000-8000-000000000004/b0000000-0000-4000-8000-000000000203.jpg'),
    ('b0000000-0000-4000-8000-000000000204'::uuid, 'd0000000-0000-4000-8000-000000000002/b0000000-0000-4000-8000-000000000204.jpg'),
    ('b0000000-0000-4000-8000-000000000205'::uuid, 'd0000000-0000-4000-8000-000000000005/b0000000-0000-4000-8000-000000000205.jpg')
) as p(id, path)
where c.id = p.id;
