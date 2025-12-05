-- Storage Bucket Setup
-- Note: You might need to create the bucket 'contest_photos' manually in the Supabase Dashboard if this script doesn't run in a migration environment that supports storage creation.
insert into storage.buckets (id, name, public)
values ('contest_photos', 'contest_photos', true)
on conflict (id) do nothing;

-- Storage Policies
create policy "Give public access to contest_photos"
  on storage.objects for select
  using ( bucket_id = 'contest_photos' );

create policy "Users can upload contest photos"
  on storage.objects for insert
  with check (
    bucket_id = 'contest_photos' and
    auth.uid() = owner
  );

create policy "Users can update their own contest photos"
  on storage.objects for update
  using (
    bucket_id = 'contest_photos' and
    auth.uid() = owner
  );

create policy "Users can delete their own contest photos"
  on storage.objects for delete
  using (
    bucket_id = 'contest_photos' and
    auth.uid() = owner
  );
