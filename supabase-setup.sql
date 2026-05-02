-- Supabase setup for the interactive film voting site.
-- Run this in Supabase SQL Editor.

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  story_ids text[] not null,
  created_at timestamptz not null default now(),
  constraint votes_story_ids_valid check (
    cardinality(story_ids) between 1 and 3
    and story_ids <@ array[
      'heir',
      'not-love-brain',
      'double-2031',
      'interview-seven',
      'live-trial',
      'ageless-apartment',
      'two-city',
      'empress',
      'top-donor',
      'restart-1999'
    ]::text[]
  )
);

create table if not exists public.vote_counts (
  story_id text primary key,
  vote_count integer not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.vote_counts (story_id, vote_count)
values
  ('heir', 0),
  ('not-love-brain', 0),
  ('double-2031', 0),
  ('interview-seven', 0),
  ('live-trial', 0),
  ('ageless-apartment', 0),
  ('two-city', 0),
  ('empress', 0),
  ('top-donor', 0),
  ('restart-1999', 0)
on conflict (story_id) do nothing;

create or replace function public.increment_vote_counts()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sid text;
begin
  foreach sid in array new.story_ids loop
    update public.vote_counts
    set vote_count = vote_count + 1,
        updated_at = now()
    where story_id = sid;
  end loop;

  return new;
end;
$$;

drop trigger if exists votes_increment_counts on public.votes;

create trigger votes_increment_counts
after insert on public.votes
for each row
execute function public.increment_vote_counts();

alter table public.votes enable row level security;
alter table public.vote_counts enable row level security;

drop policy if exists "Anyone can submit votes" on public.votes;
create policy "Anyone can submit votes"
on public.votes
for insert
to anon
with check (true);

drop policy if exists "Anyone can read vote counts" on public.vote_counts;
create policy "Anyone can read vote counts"
on public.vote_counts
for select
to anon
using (true);

grant insert on public.votes to anon;
grant select on public.vote_counts to anon;
