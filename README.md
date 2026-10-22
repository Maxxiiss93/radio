# SYNC · la radio que arma la gente

Radio online con un canal por género y subgénero. En cada canal la audiencia registrada vota el próximo tema, todos escuchan lo mismo al mismo tiempo y chatean en vivo. Stack: HTML/JS + Supabase + Vercel.

## Puesta en marcha (15 min)

1. **Supabase**: proyecto nuevo → SQL Editor → pegar y ejecutar `schema.sql` completo.
2. **Storage**: crear bucket público `tracks` y subir los MP3 (`01.mp3`, `02.mp3`, …).
3. **Taxonomía + catálogo**: ejecutar `seed.sql` (carga 20 géneros y ~110 subgéneros, más 8 temas de prueba; ajustá títulos, duraciones y subgénero de cada tema). Termina con `select radio_tick_all();` que arranca todos los canales con temas.
4. **Auth**: en Authentication → Providers, dejar Email habilitado. Para probar rápido, desactivar "Confirm email".
5. **Front**: en `index.html` completar `SUPABASE_URL` y `SUPABASE_ANON` (Project Settings → API).
6. **Deploy**: subir la carpeta a GitHub y conectarla a Vercel (sitio estático, sin build).
7. Registrarte y, en el SQL Editor: `update profiles set rol='moderador' where apodo='TU_APODO';`

## Cómo funciona

- `channels` es un árbol género → subgénero. Un tema pertenece a un subgénero; el canal del género reproduce los temas de todos sus subgéneros.
- `radio_state` tiene una fila por canal: qué tema suena y desde qué instante (hora del servidor). Un canal sin temas no arranca.
- Cada oyente calcula `offset = ahora_servidor - inicio_at` y posiciona el audio ahí; corrige deriva cada 15 s.
- Mientras suena un tema hay una ronda abierta con 5 candidatos al azar. Un voto por usuario, se puede cambiar.
- Al terminar el tema, `radio_tick(canal)` cierra la ronda, pone el ganador al aire y abre la ronda siguiente. Lo dispara un cron cada 10 s (`radio_tick_all`) y también los clientes cuando el audio termina, así el cambio es instantáneo.
- Chat, votos y estado llegan por Supabase Realtime filtrados por canal; la presencia muestra cuántos están escuchando en total y quiénes están en el canal.
- Navegación: `#/` índice de géneros con buscador (tecla `/`), `#/c/<slug>` abre un canal; los chips de arriba cambian entre el género y sus subgéneros.

## Próximos pasos posibles

- Proponer temas (la audiencia pega un link o sube un MP3, el moderador aprueba).
- Reacciones sobre el tema actual, perfiles con avatar, seguir usuarios.
- Overlay para OBS si querés retransmitir también por YouTube.
- Licencias SADAIC + AADI-CAPIF antes de pasar música comercial.

## Marca

Logotipo propio (lettering monolínea, sin tipografía de terceros). Archivos en `brand/`: `sync-wordmark*.svg` (marfil, ciruela, una tinta), `sync-mark*.svg` (la Y sola), `sync-stacked.svg`, `icon.svg` / `icon-192/512/180.png` (app), `favicon.svg`, `og.png` (compartir). Paleta: Deep Plum #542C5F · Electric Lime #C7E84B · Soft Ivory #F5F1E8.
