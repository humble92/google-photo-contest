-- Migration: Contest Management & Private Contest Features
-- Description: Adds contest editing/deletion capabilities and private contest support with pass keys

-- 1. Add new columns to contests table
ALTER TABLE public.contests 
  ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS pass_key TEXT;

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

-- 2. Add RLS policy for contest deletion
-- Hosts can delete their own contests (photos and votes will CASCADE delete automatically)
CREATE POLICY "Hosts can delete own contests"
  ON public.contests
  FOR DELETE
  USING (auth.uid() = host_user_id);

-- 3. Update contest view policy to handle private contests
-- Non-hosts can only view public contests that are active or ended
DROP POLICY IF EXISTS "Public can view active contests" ON public.contests;
CREATE POLICY "Public can view public contests"
  ON public.contests
  FOR SELECT
  USING (
    (status = 'active' OR status = 'ended') 
    AND (is_private = FALSE OR is_private IS NULL)
  );

-- Note: "Hosts can view own contests" policy already exists and allows hosts to see all their contests
-- Note: Photos and Votes have CASCADE DELETE, so deleting a contest automatically removes associated data
-- Note: No index on pass_key needed as we verify it client-side after contest is already loaded
