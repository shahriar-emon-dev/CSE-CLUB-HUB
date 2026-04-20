-- ==========================================
-- SRS CLUBS STRICT SEED (PAGE 2 / 22)
-- ==========================================
-- Purpose:
-- 1) Seed exactly six SRS-defined clubs.
-- 2) Store focus areas explicitly.
-- 3) Remove non-SRS clubs and prevent future non-SRS inserts.

-- ==========================================
-- SECTION 1: CLUBS TABLE EXTENSION
-- ==========================================

alter table public.clubs
  add column if not exists focus_area text;

-- ==========================================
-- SECTION 2: STRICT SIX-CLUB SEED
-- ==========================================

insert into public.clubs (slug, name, description, bio, focus_area, is_active)
values
  (
    'machine-learning-club',
    'Machine Learning Club',
    'AI, Data Science, Deep Learning',
    'AI, Data Science, Deep Learning',
    'AI, Data Science, Deep Learning',
    true
  ),
  (
    'competitive-programming-club',
    'Competitive Programming Club',
    'Algorithms, Contests, Problem Solving',
    'Algorithms, Contests, Problem Solving',
    'Algorithms, Contests, Problem Solving',
    true
  ),
  (
    'iot-robotics-club',
    'IoT & Robotics Club',
    'Hardware, Embedded Systems, Automation',
    'Hardware, Embedded Systems, Automation',
    'Hardware, Embedded Systems, Automation',
    true
  ),
  (
    'web-development-club',
    'Web Development Club',
    'Frontend, Backend, Full Stack Web',
    'Frontend, Backend, Full Stack Web',
    'Frontend, Backend, Full Stack Web',
    true
  ),
  (
    'software-development-club',
    'Software Development Club',
    'App Dev, System Design, Software Engineering',
    'App Dev, System Design, Software Engineering',
    'App Dev, System Design, Software Engineering',
    true
  ),
  (
    'cyber-security-club',
    'Cyber Security Club',
    'Network Security, Ethical Hacking, Cryptography',
    'Network Security, Ethical Hacking, Cryptography',
    'Network Security, Ethical Hacking, Cryptography',
    true
  )
on conflict (slug) do update
set
  name = excluded.name,
  description = excluded.description,
  bio = excluded.bio,
  focus_area = excluded.focus_area,
  is_active = true;

-- Ensure no extra clubs remain.
delete from public.clubs
where name not in (
  'Machine Learning Club',
  'Competitive Programming Club',
  'IoT & Robotics Club',
  'Web Development Club',
  'Software Development Club',
  'Cyber Security Club'
);

-- ==========================================
-- SECTION 3: ENFORCE ALLOWED CLUB NAMES
-- ==========================================

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'clubs_name_srs_allowed_check'
      and conrelid = 'public.clubs'::regclass
  ) then
    alter table public.clubs
      add constraint clubs_name_srs_allowed_check
      check (
        name in (
          'Machine Learning Club',
          'Competitive Programming Club',
          'IoT & Robotics Club',
          'Web Development Club',
          'Software Development Club',
          'Cyber Security Club'
        )
      );
  end if;
end $$;
