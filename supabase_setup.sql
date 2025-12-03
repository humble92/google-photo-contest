-- Create the photos table
create table public.photos (
  id uuid not null default gen_random_uuid (),
  contest_id uuid not null references public.contests (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  storage_path text not null,
  metadata jsonb null,
  created_at timestamp with time zone not null default now(),
  constraint photos_pkey primary key (id)
);

-- Enable RLS on photos
alter table public.photos enable row level security;

-- Policies for photos table
create policy "Public photos are viewable by everyone"
  on public.photos for select
  using ( true );

create policy "Users can insert their own photos"
  on public.photos for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own photos"
  on public.photos for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own photos"
  on public.photos for delete
  using ( auth.uid() = user_id );


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
