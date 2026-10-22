-- ============================================================
-- RADIO COMUNITARIA v2 · canales por género / subgénero
-- Ejecutar completo en el SQL Editor (proyecto nuevo o vacío).
-- ============================================================
create extension if not exists pg_cron;

-- ---------- Perfiles ----------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  apodo text not null unique check (char_length(apodo) between 2 and 24),
  avatar text,
  rol text not null default 'oyente' check (rol in ('oyente','moderador')),
  creado_en timestamptz not null default now()
);
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, apodo)
  values (new.id, coalesce(new.raw_user_meta_data->>'apodo', 'oyente_' || left(new.id::text, 6)))
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();

-- ---------- Canales (género → subgénero) ----------
create table if not exists channels (
  id serial primary key,
  slug text not null unique,
  nombre text not null,
  parent_id int references channels(id) on delete cascade,   -- null = género raíz
  emoji text,
  descripcion text,
  orden int not null default 0
);
create index if not exists channels_parent on channels(parent_id);

-- ---------- Catálogo ----------
create table if not exists tracks (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  artista text not null,
  url text not null,
  duracion_seg int not null check (duracion_seg > 10),
  portada text,
  video text,                     -- opcional: MP4/WebM corto (clip o visual) para la miniatura
  channel_id int not null references channels(id),           -- subgénero (hoja) al que pertenece
  activo boolean not null default true,
  agregado_por uuid references profiles(id),
  creado_en timestamptz not null default now()
);
create index if not exists tracks_channel on tracks(channel_id);

-- ---------- Rondas ----------
create table if not exists rounds (
  id bigint generated always as identity primary key,
  channel_id int not null references channels(id) on delete cascade,
  abierta boolean not null default true,
  ganador uuid references tracks(id),
  creado_en timestamptz not null default now(),
  cerrado_en timestamptz
);
create table if not exists candidates (
  round_id bigint references rounds(id) on delete cascade,
  track_id uuid references tracks(id) on delete cascade,
  primary key (round_id, track_id)
);
create table if not exists votes (
  round_id bigint not null,
  track_id uuid not null,
  user_id uuid not null references profiles(id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (round_id, user_id),
  foreign key (round_id, track_id) references candidates(round_id, track_id) on delete cascade
);

-- ---------- Estado: una fila por canal ----------
create table if not exists radio_state (
  channel_id int primary key references channels(id) on delete cascade,
  track_id uuid references tracks(id),
  inicio_at timestamptz,
  round_id bigint references rounds(id),
  actualizado_en timestamptz not null default now()
);

-- ---------- Chat por canal ----------
create table if not exists messages (
  id bigint generated always as identity primary key,
  channel_id int not null references channels(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  texto text not null check (char_length(texto) between 1 and 300),
  creado_en timestamptz not null default now()
);
create index if not exists messages_channel on messages(channel_id, creado_en desc);

-- ---------- Favoritos y listas por usuario ----------
create table if not exists favorite_tracks (
  user_id uuid references profiles(id) on delete cascade,
  track_id uuid references tracks(id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (user_id, track_id)
);
create table if not exists favorite_channels (
  user_id uuid references profiles(id) on delete cascade,
  channel_id int references channels(id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (user_id, channel_id)
);
create table if not exists playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  nombre text not null check (char_length(nombre) between 1 and 60),
  publica boolean not null default false,
  creado_en timestamptz not null default now()
);
create table if not exists playlist_tracks (
  playlist_id uuid references playlists(id) on delete cascade,
  track_id uuid references tracks(id) on delete cascade,
  orden int not null default 0,
  agregado_en timestamptz not null default now(),
  primary key (playlist_id, track_id)
);
create index if not exists playlists_user on playlists(user_id);

-- ---------- Vistas ----------
create or replace view candidate_votes as
select c.round_id, c.track_id, t.titulo, t.artista, t.portada, count(v.user_id)::int as votos
from candidates c join tracks t on t.id = c.track_id
left join votes v on v.round_id = c.round_id and v.track_id = c.track_id
group by c.round_id, c.track_id, t.titulo, t.artista, t.portada;

-- Canal + estado + cantidad de temas (incluye hijos) — para el índice
create or replace view channel_overview as
select ch.id, ch.slug, ch.nombre, ch.parent_id, ch.emoji, ch.descripcion, ch.orden,
       (select count(*) from tracks t where t.activo and t.channel_id in (select id from channels x where x.id = ch.id or x.parent_id = ch.id))::int as temas,
       rs.track_id, rs.inicio_at, t.titulo as sonando_titulo, t.artista as sonando_artista, t.duracion_seg as sonando_duracion, t.portada as sonando_portada, t.video as sonando_video
from channels ch
left join radio_state rs on rs.channel_id = ch.id
left join tracks t on t.id = rs.track_id;

-- ============================================================
-- Rotación (por canal)
-- ============================================================
create or replace function channel_track_ids(ch int) returns setof uuid
language sql stable as $$
  select t.id from tracks t
  where t.activo and t.channel_id in (select id from channels x where x.id = ch or x.parent_id = ch)
$$;

create or replace function open_round(ch int, n int default 5) returns bigint
language plpgsql security definer set search_path = public as $$
declare rid bigint; actual uuid;
begin
  select track_id into actual from radio_state where channel_id = ch;
  insert into rounds (channel_id) values (ch) returning id into rid;
  insert into candidates (round_id, track_id)
    select rid, id from channel_track_ids(ch) as x(id)
    where actual is null or id <> actual
    order by random() limit n;
  insert into radio_state (channel_id, round_id) values (ch, rid)
    on conflict (channel_id) do update set round_id = rid, actualizado_en = now();
  return rid;
end $$;

create or replace function resolve_round(ch int) returns void
language plpgsql security definer set search_path = public as $$
declare rid bigint; win uuid;
begin
  select round_id into rid from radio_state where channel_id = ch;
  if rid is null then perform open_round(ch); return; end if;
  select track_id into win from candidate_votes where round_id = rid order by votos desc, random() limit 1;
  if win is null then select id into win from channel_track_ids(ch) as x(id) order by random() limit 1; end if;
  if win is null then return; end if;  -- canal sin temas
  update rounds set abierta = false, ganador = win, cerrado_en = now() where id = rid;
  update radio_state set track_id = win, inicio_at = now(), actualizado_en = now() where channel_id = ch;
  perform open_round(ch);
end $$;

-- Tick de un canal (lo llaman los clientes al terminar el tema)
create or replace function radio_tick(ch int) returns void
language plpgsql security definer set search_path = public as $$
declare s radio_state; d int;
begin
  if not exists (select 1 from channel_track_ids(ch)) then return; end if;
  select * into s from radio_state where channel_id = ch for update;
  if s.track_id is null then perform resolve_round(ch); return; end if;
  select duracion_seg into d from tracks where id = s.track_id;
  if now() >= s.inicio_at + make_interval(secs => d) then perform resolve_round(ch); end if;
end $$;

-- Tick global (cron): todos los canales que tienen temas
create or replace function radio_tick_all() returns void
language plpgsql security definer set search_path = public as $$
declare ch record;
begin
  for ch in select distinct c.id from channels c where exists (select 1 from channel_track_ids(c.id)) loop
    perform radio_tick(ch.id);
  end loop;
end $$;

create or replace function server_now() returns timestamptz language sql stable as $$ select now() $$;

select cron.unschedule('radio_tick') where exists (select 1 from cron.job where jobname = 'radio_tick');
select cron.schedule('radio_tick', '10 seconds', 'select public.radio_tick_all()');

-- ============================================================
-- RLS
-- ============================================================
alter table profiles enable row level security;  alter table channels enable row level security;
alter table tracks enable row level security;    alter table rounds enable row level security;
alter table candidates enable row level security; alter table votes enable row level security;
alter table radio_state enable row level security; alter table messages enable row level security;
alter table favorite_tracks enable row level security; alter table favorite_channels enable row level security;
alter table playlists enable row level security; alter table playlist_tracks enable row level security;

create policy "leer" on profiles for select using (true);
create policy "leer" on channels for select using (true);
create policy "leer" on tracks for select using (true);
create policy "leer" on rounds for select using (true);
create policy "leer" on candidates for select using (true);
create policy "leer" on votes for select using (true);
create policy "leer" on radio_state for select using (true);
create policy "leer" on messages for select using (true);

create policy "perfil propio" on profiles for update
  using (auth.uid() = id) with check (auth.uid() = id and rol = (select rol from profiles where id = auth.uid()));

create policy "votar" on votes for insert with check (
  auth.uid() = user_id
  and exists (select 1 from radio_state rs join rounds r on r.id = rs.round_id where rs.round_id = votes.round_id and r.abierta));
create policy "cambiar voto" on votes for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id and exists (select 1 from rounds where id = round_id and abierta));

-- Favoritos: cada uno ve y maneja los suyos
create policy "fav tracks propio" on favorite_tracks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "fav channels propio" on favorite_channels for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- Listas: el dueño todo; las públicas las ve cualquiera
create policy "listas ver" on playlists for select using (publica or auth.uid() = user_id);
create policy "listas propio" on playlists for insert with check (auth.uid() = user_id);
create policy "listas editar" on playlists for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "listas borrar" on playlists for delete using (auth.uid() = user_id);
create policy "lista temas ver" on playlist_tracks for select using (exists (select 1 from playlists p where p.id = playlist_id and (p.publica or p.user_id = auth.uid())));
create policy "lista temas propio" on playlist_tracks for all
  using (exists (select 1 from playlists p where p.id = playlist_id and p.user_id = auth.uid()))
  with check (exists (select 1 from playlists p where p.id = playlist_id and p.user_id = auth.uid()));

create policy "chat escribir" on messages for insert with check (auth.uid() = user_id);
create policy "chat borrar" on messages for delete
  using (auth.uid() = user_id or exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));

create policy "admin" on tracks for all
  using (exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'))
  with check (exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));
create policy "admin" on channels for all
  using (exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'))
  with check (exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));

-- ---------- Fotos de perfil (Storage) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
create policy "avatars leer" on storage.objects for select using (bucket_id = 'avatars');
create policy "avatars subir propio" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars actualizar propio" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars borrar propio" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

alter publication supabase_realtime add table radio_state, votes, messages;

grant execute on function radio_tick(int), server_now(), channel_track_ids(int) to anon, authenticated;
revoke execute on function open_round(int,int), resolve_round(int), radio_tick_all() from anon, authenticated;
