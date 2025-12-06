-- Migration: Contest Management & Private Contest Features
-- Description: Adds contest editing/deletion capabilities and private contest support with pass keys

-- 1. Add new columns to contests table
ALTER TABLE public.contests 
  ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS pass_key TEXT;

-- 2. RLS Policies for Contests

-- Allow Authenticated Users to Create Contests
-- Users should be able to insert if they are the host
DROP POLICY IF EXISTS "Users can create contests" ON public.contests;
CREATE POLICY "Users can create contests"
  ON public.contests
  FOR INSERT
  WITH CHECK ( auth.uid() = host_user_id );

-- Allow Hosts to View their own contests (including drafts)
DROP POLICY IF EXISTS "Hosts can view own contests" ON public.contests;
CREATE POLICY "Hosts can view own contests"
  ON public.contests
  FOR SELECT
  USING ( auth.uid() = host_user_id );

-- Allow ALL users to view active/ended contests (both public AND private)
-- Private contests will show with lock icon, pass key required for entry
DROP POLICY IF EXISTS "Public can view active contests" ON public.contests;
DROP POLICY IF EXISTS "Public can view public contests" ON public.contests;
DROP POLICY IF EXISTS "Users can view all contests" ON public.contests;
CREATE POLICY "Users can view all active/ended contests"
  ON public.contests
  FOR SELECT
  USING (
    status = 'active' OR status = 'ended'
    -- No is_private filter! All contests visible in lists
  );

-- Allow Hosts to Update their own contests
DROP POLICY IF EXISTS "Hosts can update own contests" ON public.contests;
CREATE POLICY "Hosts can update own contests"
  ON public.contests
  FOR UPDATE
  USING ( auth.uid() = host_user_id );

-- Allow Hosts to Delete their own contests
DROP POLICY IF EXISTS "Hosts can delete own contests" ON public.contests;
CREATE POLICY "Hosts can delete own contests"
  ON public.contests
  FOR DELETE
  USING (auth.uid() = host_user_id);

-- Note: Photos and Votes have CASCADE DELETE, so deleting a contest automatically removes associated data
-- Note: Pass key verification is done client-side when accessing contest details
-- Note: Private contests appear in lists with a lock icon, but require pass key to enter
