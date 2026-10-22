
-- ---------- Reproducciones por canal (ranking cuando no hay oyentes en vivo) ----------
create table if not exists channel_plays (
  channel_id int references channels(id) on delete cascade,
  dia date not null default current_date,
  plays int not null default 0,
  primary key (channel_id, dia)
);
alter table channel_plays enable row level security;
drop policy if exists "leer" on channel_plays;
create policy "leer" on channel_plays for select using (true);
create or replace function log_play(ch int) returns void
language sql security definer set search_path = public as $$
  insert into channel_plays (channel_id, dia, plays) values (ch, current_date, 1)
  on conflict (channel_id, dia) do update set plays = channel_plays.plays + 1;
$$;
grant execute on function log_play(int) to anon, authenticated;

drop view if exists channel_overview;
create view channel_overview as
select ch.id, ch.slug, ch.nombre, ch.parent_id, ch.emoji, ch.descripcion, ch.orden,
       (select count(*) from tracks t where t.activo and t.channel_id in (select id from channels x where x.id = ch.id or x.parent_id = ch.id))::int as temas,
       (select coalesce(sum(p.plays),0) from channel_plays p where p.dia >= current_date - 6 and p.channel_id in (select id from channels x where x.id = ch.id or x.parent_id = ch.id))::int as plays_7d,
       rs.track_id, rs.inicio_at, t.titulo as sonando_titulo, t.artista as sonando_artista, t.duracion_seg as sonando_duracion, t.portada as sonando_portada, t.video as sonando_video
from channels ch
left join radio_state rs on rs.channel_id = ch.id
left join tracks t on t.id = rs.track_id;