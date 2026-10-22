-- ============================================================
-- SYNC · Cuentas de menores supervisadas + chat separado
-- Ejecutar completo en el SQL Editor (después de schema.sql).
-- ============================================================

-- ---------- Perfiles: menor / tutor / chat ----------
alter table profiles add column if not exists es_menor boolean not null default false;
alter table profiles add column if not exists tutor_id uuid references profiles(id) on delete set null;
alter table profiles add column if not exists chat_habilitado boolean not null default true;
create index if not exists profiles_tutor on profiles(tutor_id);

-- ---------- Códigos de tutor ----------
create table if not exists tutor_codes (
  code text primary key,
  tutor_id uuid not null references profiles(id) on delete cascade,
  usado_por uuid references profiles(id) on delete set null,
  creado_en timestamptz not null default now(),
  usado_en timestamptz
);
alter table tutor_codes enable row level security;
drop policy if exists "codigos propios" on tutor_codes;
create policy "codigos propios" on tutor_codes for select using (auth.uid() = tutor_id);

-- El tutor (un adulto) genera un código de 6 caracteres para vincular a un menor.
create or replace function crear_codigo_tutor() returns text
language plpgsql security definer set search_path = public as $$
declare c text; i int := 0;
begin
  if auth.uid() is null then raise exception 'Tenés que iniciar sesión'; end if;
  if (select es_menor from profiles where id = auth.uid()) then raise exception 'Una cuenta supervisada no puede generar códigos'; end if;
  loop
    c := upper(substr(translate(encode(gen_random_bytes(6),'base64'),'+/=0OIl','ABCDEFG'),1,6));
    begin
      insert into tutor_codes (code, tutor_id) values (c, auth.uid());
      return c;
    exception when unique_violation then i := i + 1; if i > 10 then raise; end if;
    end;
  end loop;
end $$;

-- Vincula al usuario actual (o a uno dado, uso interno) con el tutor del código.
create or replace function vincular_menor(p_code text, p_user uuid default null) returns void
language plpgsql security definer set search_path = public as $$
declare t uuid; u uuid := coalesce(p_user, auth.uid());
begin
  if u is null then raise exception 'Tenés que iniciar sesión'; end if;
  select tutor_id into t from tutor_codes where code = upper(trim(p_code)) and usado_por is null and creado_en > now() - interval '7 days';
  if t is null then raise exception 'Código inválido o vencido'; end if;
  if t = u then raise exception 'No podés usar tu propio código'; end if;
  update tutor_codes set usado_por = u, usado_en = now() where code = upper(trim(p_code));
  update profiles set es_menor = true, tutor_id = t, chat_habilitado = true where id = u;
end $$;

-- El tutor libera la supervisión (el menor cumplió 18).
create or replace function liberar_menor(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from profiles where id = p_user and tutor_id = auth.uid()) then raise exception 'No supervisás esa cuenta'; end if;
  update profiles set es_menor = false, tutor_id = null, chat_habilitado = true where id = p_user;
end $$;

-- Alta: si el registro trae codigo_tutor en los metadatos, vincula de una.
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, apodo)
  values (new.id, coalesce(new.raw_user_meta_data->>'apodo', 'oyente_' || left(new.id::text, 6)))
  on conflict (id) do nothing;
  if coalesce(new.raw_user_meta_data->>'codigo_tutor','') <> '' then
    begin perform vincular_menor(new.raw_user_meta_data->>'codigo_tutor', new.id);
    exception when others then null; -- código inválido: queda como cuenta común y puede vincularse después
    end;
  end if;
  return new;
end $$;

-- Un menor no puede cambiar su propio estado; el tutor sí puede pausar/reanudar el chat.
drop policy if exists "perfil propio" on profiles;
create policy "perfil propio" on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id
    and rol = (select rol from profiles p where p.id = auth.uid())
    and es_menor = (select es_menor from profiles p where p.id = auth.uid())
    and tutor_id is not distinct from (select tutor_id from profiles p where p.id = auth.uid())
    and chat_habilitado = (select chat_habilitado from profiles p where p.id = auth.uid()));
drop policy if exists "tutor edita" on profiles;
create policy "tutor edita" on profiles for update
  using (tutor_id = auth.uid()) with check (tutor_id = auth.uid() and es_menor);

-- ---------- Chat: salas separadas ----------
alter table messages add column if not exists sala text not null default 'adultos' check (sala in ('adultos','menores'));
create index if not exists messages_sala on messages(channel_id, sala, creado_en desc);

-- Sala del usuario actual (null = anónimo → ve adultos)
create or replace function mi_sala() returns text
language sql stable security definer set search_path = public as $$
  select case when coalesce((select es_menor from profiles where id = auth.uid()), false) then 'menores' else 'adultos' end
$$;

-- Filtro de contenido para la sala de menores: datos de contacto, links y lenguaje ofensivo.
create or replace function texto_apto_menores(t text) returns text
language plpgsql immutable as $$
declare s text := lower(t);
begin
  if s ~ '(https?://|www\.|\.com\b|\.ar\b|\.net\b|\.org\b)' then return 'En el chat de menores no se pueden compartir links.'; end if;
  if s ~ '[0-9][0-9 .\-]{6,}[0-9]' then return 'En el chat de menores no se pueden compartir números de teléfono.'; end if;
  if s ~ '[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}' then return 'En el chat de menores no se pueden compartir mails.'; end if;
  if s ~ '(\binsta(gram)?\b|\bwhats?app\b|\btelegram\b|\bsnap(chat)?\b|\btiktok\b|\bdiscord\b|\bfacebook\b|\busuario:|\bagregame\b|\bagregáme\b|\bseguime\b|\bpasame tu\b|\bpasá tu\b)' then return 'En el chat de menores no se comparten redes ni formas de contacto.'; end if;
  if s ~ '(\bputa\b|\bputo\b|\bmierda\b|\bpelotud[oa]s?\b|\bboludo\b|\bboluda\b|\bforr[oa]s?\b|\bconch[a]\b|\bcarajo\b|\bculo\b|\bverga\b|\bpija\b|\bhij[oa] de puta\b|\bidiota\b|\bimbécil\b|\bestúpid[oa]\b|\bmogólic[oa]\b|\bretrasad[oa]\b|\bmatate\b|\bsuicid)' then return 'Ese mensaje no va en el chat de menores. Decilo de otra forma.'; end if;
  return null;
end $$;

create or replace function messages_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare p profiles%rowtype; motivo text;
begin
  select * into p from profiles where id = new.user_id;
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
drop trigger if exists messages_sala on messages;
create trigger messages_sala before insert on messages for each row execute function messages_before_insert();

-- Lectura: cada uno ve su sala; el tutor además ve los mensajes de los menores que supervisa.
drop policy if exists "leer" on messages;
create policy "leer" on messages for select using (
  sala = mi_sala()
  or exists (select 1 from profiles p where p.id = messages.user_id and p.tutor_id = auth.uid())
);

-- Mensajes viejos sin sala quedan como adultos (default). Listo.
