create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'student' check (role in ('student','parent','coach','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  grade int,
  age int,
  phone text,
  track text not null default 'VEXcode C++',
  current_module int not null default 1,
  current_session int not null default 1,
  status text not null default 'on-track',
  competition_date date,
  github_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  coach_id uuid references public.profiles(id) on delete set null,
  session_date timestamptz,
  topic text not null,
  module int not null default 1,
  session_num int not null default 1,
  duration_minutes int not null default 90,
  parent_summary text,
  coach_notes text,
  challenge_text text,
  exit_met boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  session_id uuid references public.sessions(id) on delete set null,
  text text not null,
  status text not null default 'in-progress' check (status in ('in-progress','complete')),
  created_at timestamptz not null default now()
);

create table if not exists public.skills (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.student_skills (
  student_id uuid not null references public.students(id) on delete cascade,
  skill_id uuid not null references public.skills(id) on delete cascade,
  earned_at timestamptz not null default now(),
  primary key (student_id, skill_id)
);

create table if not exists public.competition_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  event_name text not null,
  event_date date,
  placement text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.student_metrics (
  student_id uuid primary key references public.students(id) on delete cascade,
  github_commits int not null default 0,
  notebook_pages int not null default 0,
  hours_coached numeric not null default 0,
  total_sessions int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.booking_requests (
  id uuid primary key default gen_random_uuid(),
  session_type text not null,
  level text,
  preferred_times text,
  student_name text not null,
  grade text,
  parent_email text not null,
  parent_phone text,
  preferred_coach text,
  status text not null default 'new' check (status in ('new','contacted','scheduled','closed')),
  created_at timestamptz not null default now()
);

insert into public.skills (name)
values
  ('Override Game Rules'),
  ('Kit Identification'),
  ('VS Code Setup'),
  ('Drivetrain Assembly'),
  ('Motor Control'),
  ('Sensor Reading'),
  ('Gear Ratios'),
  ('Competition Drivetrain'),
  ('Mechanism Design'),
  ('GitHub Branching'),
  ('Sensor-Based Autonomous'),
  ('PID Tuning'),
  ('Multi-Path Autonomous'),
  ('Skills Run'),
  ('Driver Drills'),
  ('Scouting System'),
  ('Notebook Standards'),
  ('CAD Basics')
on conflict (name) do nothing;

alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.sessions enable row level security;
alter table public.challenges enable row level security;
alter table public.skills enable row level security;
alter table public.student_skills enable row level security;
alter table public.competition_records enable row level security;
alter table public.student_metrics enable row level security;
alter table public.booking_requests enable row level security;

create or replace function public.owns_student(target_student_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.students
    where id = target_student_id
    and profile_id = auth.uid()
  );
$$;

drop policy if exists "Profiles readable by owner or admin" on public.profiles;
drop policy if exists "Profiles insertable by owner or admin" on public.profiles;
drop policy if exists "Profiles updateable by owner or admin" on public.profiles;
drop policy if exists "Users can read their own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Admins can manage profiles" on public.profiles;
drop policy if exists "Students manageable by owner or admin" on public.students;
drop policy if exists "Sessions readable by student owner or admin" on public.sessions;
drop policy if exists "Sessions manageable by admin" on public.sessions;
drop policy if exists "Challenges readable by student owner or admin" on public.challenges;
drop policy if exists "Challenges manageable by student owner or admin" on public.challenges;
drop policy if exists "Skills readable by authenticated users" on public.skills;
drop policy if exists "Student skills readable by student owner or admin" on public.student_skills;
drop policy if exists "Student skills manageable by admin" on public.student_skills;
drop policy if exists "Competition records readable by student owner or admin" on public.competition_records;
drop policy if exists "Competition records manageable by student owner or admin" on public.competition_records;
drop policy if exists "Student metrics readable by student owner or admin" on public.student_metrics;
drop policy if exists "Student metrics manageable by student owner or admin" on public.student_metrics;
drop policy if exists "Profiles dev access" on public.profiles;
drop policy if exists "Students dev access" on public.students;
drop policy if exists "Sessions dev access" on public.sessions;
drop policy if exists "Challenges dev access" on public.challenges;
drop policy if exists "Skills dev read" on public.skills;
drop policy if exists "Student skills dev access" on public.student_skills;
drop policy if exists "Competition records dev access" on public.competition_records;
drop policy if exists "Student metrics dev access" on public.student_metrics;
drop policy if exists "Booking requests dev access" on public.booking_requests;

create policy "Profiles dev access"
on public.profiles for all
to anon, authenticated
using (true)
with check (true);

create policy "Students dev access"
on public.students for all
to anon, authenticated
using (true)
with check (true);

create policy "Sessions dev access"
on public.sessions for all
to anon, authenticated
using (true)
with check (true);

create policy "Challenges dev access"
on public.challenges for all
to anon, authenticated
using (true)
with check (true);

create policy "Skills dev read"
on public.skills for select
to anon, authenticated
using (true);

create policy "Student skills dev access"
on public.student_skills for all
to anon, authenticated
using (true)
with check (true);

create policy "Competition records dev access"
on public.competition_records for all
to anon, authenticated
using (true)
with check (true);

create policy "Student metrics dev access"
on public.student_metrics for all
to anon, authenticated
using (true)
with check (true);

create policy "Booking requests dev access"
on public.booking_requests for all
to anon, authenticated
using (true)
with check (true);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_role text;
  new_student_id uuid;
begin
  new_role := coalesce(new.raw_user_meta_data->>'role', 'student');

  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    new_role
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    role = excluded.role;

  if new_role = 'student' then
    insert into public.students (profile_id, grade, track, current_module, current_session, status)
    values (
      new.id,
      nullif(new.raw_user_meta_data->>'grade', '')::int,
      coalesce(new.raw_user_meta_data->>'track', 'VEXcode C++'),
      1,
      1,
      'on-track'
    )
    on conflict (profile_id) do update set
      track = excluded.track
    returning id into new_student_id;

    insert into public.student_metrics (student_id)
    values (new_student_id)
    on conflict (student_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.students (profile_id, track, current_module, current_session, status)
select
  p.id,
  'VEXcode C++',
  1,
  1,
  'on-track'
from public.profiles p
where p.role = 'student'
and not exists (
  select 1 from public.students s
  where s.profile_id = p.id
);

insert into public.student_metrics (student_id)
select s.id
from public.students s
where not exists (
  select 1 from public.student_metrics m
  where m.student_id = s.id
);
