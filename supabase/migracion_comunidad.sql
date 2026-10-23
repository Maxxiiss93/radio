-- ============================================================
-- SYNC · Pedidos de temas, reportes de chat y silencios
-- Aplicada en producción el 22/10/2026. Para proyectos nuevos: ejecutar después de schema.sql.
-- ============================================================

-- Silencio temporal (lo pone un moderador desde Reportes)
alter table profiles add column if not exists silenciado_hasta timestamptz;

-- ---------- Pedidos de temas ----------
create table if not exists track_requests (
  id bigint generated always as identity primary key,
  channel_id int not null references channels(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  url text not null check (char_length(url) between 10 and 500),
  nota text check (char_length(nota) <= 200),
  estado text not null default 'pendiente' check (estado in ('pendiente','aprobado','rechazado')),
  creado_en timestamptz not null default now(),
  resuelto_en timestamptz
);
create index if not exists track_requests_estado on track_requests(estado, creado_en desc);
alter table track_requests enable row level security;
create policy "pedidos ver" on track_requests for select using (
  auth.uid() = user_id or exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));
create policy "pedidos crear" on track_requests for insert with check (
  auth.uid() = user_id
  and coalesce((select silenciado_hasta from profiles where id = auth.uid()), now() - interval '1 second') < now()
  and (select count(*) from track_requests r where r.user_id = auth.uid() and r.estado = 'pendiente') < 5);
create policy "pedidos resolver" on track_requests for update using (
  exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));

-- ---------- Reportes de mensajes ----------
create table if not exists message_reports (
  id bigint generated always as identity primary key,
  message_id bigint not null references messages(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  motivo text not null check (motivo in ('ofensivo','spam','contacto','otro')),
  creado_en timestamptz not null default now(),
  resuelto boolean not null default false,
  unique (message_id, user_id)
);
alter table message_reports enable row level security;
create policy "reportes crear" on message_reports for insert with check (auth.uid() = user_id);
create policy "reportes ver" on message_reports for select using (
  auth.uid() = user_id or exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));
create policy "reportes resolver" on message_reports for update using (
  exists (select 1 from profiles where id = auth.uid() and rol = 'moderador'));
-- El moderador necesita leer el mensaje reportado aunque sea de otra sala
drop policy if exists "leer" on messages;
create policy "leer" on messages for select using (
  sala = mi_sala()
  or exists (select 1 from profiles p where p.id = messages.user_id and p.tutor_id = auth.uid())
  or exists (select 1 from profiles where id = auth.uid() and rol = 'moderador')
);

-- Silenciado: no puede chatear
create or replace function messages_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare p profiles%rowtype; motivo text;
begin
  select * into p from profiles where id = new.user_id;
  if p.silenciado_hasta is not null and p.silenciado_hasta > now() then raise exception 'Tu cuenta está silenciada hasta %', to_char(p.silenciado_hasta at time zone 'America/Argentina/Buenos_Aires','HH24:MI'); end if;
  if p.es_menor then
    if not p.chat_habilitado then raise exception 'Tu tutor pausó el chat de esta cuenta'; end if;
    new.sala := 'menores';
    motivo := texto_apto_menores(new.texto);
    if motivo is not null then raise exception '%', motivo; end if;
  else
    new.sala := 'adultos';
  end if;
  return new;
end $$;

-- Silenciar (solo moderador): horas desde ahora
create or replace function silenciar(p_user uuid, p_horas int) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from profiles where id = auth.uid() and rol = 'moderador') then raise exception 'Solo moderadores'; end if;
  update profiles set silenciado_hasta = case when p_horas <= 0 then null else now() + make_interval(hours => p_horas) end where id = p_user;
end $$;

-- Vista para el panel: reportes pendientes con mensaje y autor
create or replace view reportes_pendientes as
select r.id, r.message_id, r.motivo, r.creado_en, m.texto, m.channel_id, m.user_id as autor_id, p.apodo as autor, p.silenciado_hasta,
       (select count(*) from message_reports x where x.message_id = r.message_id) as veces
from message_reports r join messages m on m.id = r.message_id join profiles p on p.id = m.user_id
where not r.resuelto;
alter view reportes_pendientes set (security_invoker = true);
