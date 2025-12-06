-- Users can view all votes (for vote display)
CREATE POLICY "Users can view votes" ON public.votes
    FOR SELECT USING (true);

-- Enable deletion of own votes
CREATE POLICY "Users can delete own votes" ON public.votes
  FOR DELETE USING (auth.uid() = user_id);