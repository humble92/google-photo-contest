-- Alter photos table to match the new schema

-- 1. Add/Ensure 'storage_path' exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'storage_path') THEN
        ALTER TABLE public.photos ADD COLUMN storage_path TEXT;
    END IF;
END $$;

-- 2. Add/Ensure 'user_id' exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'user_id') THEN
        ALTER TABLE public.photos ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Add/Ensure 'vote_count' exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'vote_count') THEN
        ALTER TABLE public.photos ADD COLUMN vote_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- 4. Handle 'metadata' vs 'meta_data'
-- If 'metadata' exists but 'meta_data' does not, rename it.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'metadata') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'meta_data') THEN
        ALTER TABLE public.photos RENAME COLUMN metadata TO meta_data;
    ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'meta_data') THEN
        ALTER TABLE public.photos ADD COLUMN meta_data JSONB;
    END IF;
END $$;

-- 5. Drop 'google_media_item_id' if it exists (optional, but cleaner)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'photos' AND column_name = 'google_media_item_id') THEN
        ALTER TABLE public.photos DROP COLUMN google_media_item_id;
    END IF;
END $$;

-- 6. Ensure RLS policies are correct for the new columns
-- (Policies usually reference columns dynamically, but if we added user_id, we need to make sure policies use it)

-- Update policies to use user_id if they were using something else or if they need to be re-created.
-- For safety, we can re-run the policy creation (Supabase usually handles this, but explicit is good).

-- Enable RLS on photos
alter table public.photos enable row level security;

-- Policies for photos table
create policy "Public photos are viewable by everyone"
  on public.photos for select
  using ( true );

-- Allow Authenticated Users to Create Contests
-- Users should be able to insert if they are the host
DROP POLICY IF EXISTS "Users can create contests" ON public.contests;
CREATE POLICY "Users can create contests"
  ON public.contests
  FOR INSERT
  WITH CHECK ( auth.uid() = host_user_id );

-- Allow Hosts to View their own "Draft" Contests
-- The existing policy might only show 'active' or 'ended'.
-- We need to ensure hosts can see their own contests regardless of status.
DROP POLICY IF EXISTS "Hosts can view own contests" ON public.contests;
CREATE POLICY "Hosts can view own contests"
  ON public.contests
  FOR SELECT
  USING ( auth.uid() = host_user_id );

-- Allow Hosts to Update their own contests (Already likely exists, but good to ensure)
DROP POLICY IF EXISTS "Hosts can update own contests" ON public.contests;
CREATE POLICY "Hosts can update own contests"
  ON public.contests
  FOR UPDATE
  USING ( auth.uid() = host_user_id );

