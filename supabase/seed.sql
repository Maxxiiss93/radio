-- ============================================================
-- Taxonomía de géneros y subgéneros + catálogo de prueba
-- Ejecutar después de schema.sql.
-- ============================================================

-- ---------- Géneros raíz ----------
insert into channels (slug, nombre, emoji, descripcion, orden) values
('rock',        'Rock',             '🎸', 'Del clásico al alternativo',                 1),
('pop',         'Pop',              '✨', 'Lo que suena en todos lados',                 2),
('urbano',      'Urbano',           '🔥', 'Trap, reggaetón, RKT, hip hop',               3),
('electronica', 'Electrónica',      '🎛️', 'House, techno, drum & bass y más',           4),
('cumbia',      'Cumbia',           '💃', 'De la villera a la santafesina',              5),
('folklore',    'Folklore',         '🪗', 'Chacarera, zamba, chamamé',                   6),
('tango',       'Tango',            '🌹', 'Clásico, electrónico y nuevo tango',          7),
('latino',      'Latino',           '🌴', 'Salsa, bachata, merengue, vallenato',         8),
('jazz-blues',  'Jazz & Blues',     '🎷', 'Standards, fusión, blues eléctrico',          9),
('metal',       'Metal',            '🤘', 'Heavy, thrash, death, progresivo',           10),
('punk',        'Punk',             '🧷', 'Hardcore, skate, pop punk',                  11),
('hip-hop',     'Hip Hop',          '🎤', 'Boom bap, freestyle, lo-fi',                 12),
('reggae-ska',  'Reggae & Ska',     '🟢', 'Roots, dub, ska argentino',                  13),
('indie',       'Indie',            '🌙', 'Indie rock, dream pop, folk',                14),
('clasica',     'Clásica',          '🎻', 'Barroco, romántico, contemporáneo',          15),
('soul-funk',   'Soul & Funk',      '🕺', 'R&B, disco, neo soul',                       16),
('country-folk','Country & Folk',   '🤠', 'Americana, folk, bluegrass',                 17),
('infantil',    'Infantil',         '🧸', 'Para los más chicos',                        18),
('ambient',     'Ambient & Chill',  '🌊', 'Para estudiar, trabajar o dormir',           19),
('local',       'Artistas locales', '📍', 'Bandas y solistas de La Pampa',              20);

-- ---------- Subgéneros ----------
with p as (select id, slug from channels)
insert into channels (slug, nombre, parent_id, orden)
select s.slug, s.nombre, p.id, s.orden from (values
 -- Rock
 ('rock-nacional',   'Rock nacional',    'rock', 1), ('rock-clasico',   'Rock clásico',    'rock', 2), ('rock-alternativo','Rock alternativo','rock', 3),
 ('hard-rock',       'Hard rock',        'rock', 4), ('grunge',         'Grunge',          'rock', 5), ('rock-progresivo','Rock progresivo', 'rock', 6),
 ('rock-barrial',    'Rock barrial',     'rock', 7), ('psicodelico',    'Psicodélico',     'rock', 8),
 -- Pop
 ('pop-latino',      'Pop latino',       'pop', 1), ('pop-internacional','Pop internacional','pop',2), ('pop-rock',       'Pop rock',        'pop', 3),
 ('synthpop',        'Synthpop',         'pop', 4), ('k-pop',          'K-pop',           'pop', 5), ('baladas',        'Baladas',         'pop', 6),
 -- Urbano
 ('trap',            'Trap',             'urbano', 1), ('reggaeton',    'Reggaetón',       'urbano', 2), ('rkt',          'RKT',             'urbano', 3),
 ('drill',           'Drill',            'urbano', 4), ('dembow',       'Dembow',          'urbano', 5), ('afrobeats',    'Afrobeats',       'urbano', 6),
 -- Electrónica
 ('house',           'House',            'electronica', 1), ('techno',   'Techno',          'electronica', 2), ('trance',     'Trance',          'electronica', 3),
 ('drum-and-bass',   'Drum & Bass',      'electronica', 4), ('dubstep',  'Dubstep',         'electronica', 5), ('edm',        'EDM / Big room',  'electronica', 6),
 ('deep-house',      'Deep house',       'electronica', 7), ('minimal',  'Minimal',         'electronica', 8), ('synthwave',  'Synthwave',       'electronica', 9),
 -- Cumbia
 ('cumbia-villera',  'Cumbia villera',   'cumbia', 1), ('cumbia-santafesina','Cumbia santafesina','cumbia',2), ('cumbia-pop','Cumbia pop','cumbia',3),
 ('cumbia-420',      'Cumbia 420',       'cumbia', 4), ('cumbia-colombiana','Cumbia colombiana','cumbia',5), ('cuarteto', 'Cuarteto',  'cumbia', 6),
 -- Folklore
 ('chacarera',       'Chacarera',        'folklore', 1), ('zamba',      'Zamba',           'folklore', 2), ('chamame',    'Chamamé',         'folklore', 3),
 ('folklore-fusion', 'Folklore fusión',  'folklore', 4), ('gato-escondido','Gato y escondido','folklore',5), ('andino',   'Andino',          'folklore', 6),
 -- Tango
 ('tango-clasico',   'Tango clásico',    'tango', 1), ('tango-electronico','Tango electrónico','tango',2), ('milonga',  'Milonga',         'tango', 3), ('nuevo-tango','Nuevo tango','tango',4),
 -- Latino
 ('salsa',           'Salsa',            'latino', 1), ('bachata',     'Bachata',         'latino', 2), ('merengue',   'Merengue',        'latino', 3),
 ('vallenato',       'Vallenato',        'latino', 4), ('bossa-nova',  'Bossa nova',      'latino', 5), ('mpb',        'MPB',             'latino', 6),
 -- Jazz & Blues
 ('jazz-standards',  'Standards',        'jazz-blues', 1), ('jazz-fusion','Fusión',        'jazz-blues', 2), ('smooth-jazz','Smooth jazz',   'jazz-blues', 3),
 ('blues-electrico', 'Blues eléctrico',  'jazz-blues', 4), ('blues-acustico','Blues acústico','jazz-blues',5), ('bebop',     'Bebop',         'jazz-blues', 6),
 -- Metal
 ('heavy-metal',     'Heavy metal',      'metal', 1), ('thrash',       'Thrash',          'metal', 2), ('death-metal',  'Death metal',     'metal', 3),
 ('black-metal',     'Black metal',      'metal', 4), ('metal-progresivo','Metal progresivo','metal',5), ('metalcore',  'Metalcore',       'metal', 6), ('nu-metal','Nu metal','metal',7),
 -- Punk
 ('punk-rock',       'Punk rock',        'punk', 1), ('hardcore',      'Hardcore',        'punk', 2), ('pop-punk',     'Pop punk',        'punk', 3), ('post-punk','Post-punk','punk',4),
 -- Hip Hop
 ('boom-bap',        'Boom bap',         'hip-hop', 1), ('freestyle',   'Freestyle',       'hip-hop', 2), ('lo-fi-hip-hop','Lo-fi hip hop',  'hip-hop', 3), ('rap-latino','Rap latino','hip-hop',4),
 -- Reggae & Ska
 ('roots-reggae',    'Roots reggae',     'reggae-ska', 1), ('dub',       'Dub',             'reggae-ska', 2), ('ska',        'Ska',             'reggae-ska', 3), ('dancehall','Dancehall','reggae-ska',4),
 -- Indie
 ('indie-rock',      'Indie rock',       'indie', 1), ('indie-pop',    'Indie pop',       'indie', 2), ('dream-pop',    'Dream pop',       'indie', 3),
 ('indie-folk',      'Indie folk',       'indie', 4), ('shoegaze',     'Shoegaze',        'indie', 5), ('bedroom-pop',  'Bedroom pop',     'indie', 6),
 -- Clásica
 ('barroco',         'Barroco',          'clasica', 1), ('clasicismo',  'Clasicismo',      'clasica', 2), ('romantico',   'Romántico',       'clasica', 3),
 ('contemporanea',   'Contemporánea',    'clasica', 4), ('opera',       'Ópera',           'clasica', 5), ('bandas-sonoras','Bandas sonoras','clasica', 6),
 -- Soul & Funk
 ('soul',            'Soul',             'soul-funk', 1), ('funk',       'Funk',            'soul-funk', 2), ('disco',       'Disco',           'soul-funk', 3),
 ('rnb',             'R&B',              'soul-funk', 4), ('neo-soul',   'Neo soul',        'soul-funk', 5),
 -- Country & Folk
 ('country',         'Country',          'country-folk', 1), ('americana','Americana',      'country-folk', 2), ('bluegrass','Bluegrass',       'country-folk', 3), ('folk-acustico','Folk acústico','country-folk',4),
 -- Infantil
 ('canciones-infantiles','Canciones infantiles','infantil',1), ('cuentos-musicales','Cuentos musicales','infantil',2),
 -- Ambient & Chill
 ('ambient-puro',    'Ambient',          'ambient', 1), ('lo-fi-beats',  'Lo-fi beats',     'ambient', 2), ('chillout',    'Chillout',        'ambient', 3),
 ('naturaleza',      'Sonidos de naturaleza','ambient',4), ('para-dormir','Para dormir',     'ambient', 5),
 -- Local
 ('local-rock',      'Rock pampeano',    'local', 1), ('local-folklore','Folklore pampeano','local', 2), ('local-urbano','Urbano pampeano', 'local', 3), ('local-otros','Otros',  'local', 4)
) as s(slug, nombre, parent_slug, orden)
join p on p.slug = s.parent_slug;

-- ---------- Catálogo de prueba ----------
-- Subí los MP3 a un bucket público "tracks" y ajustá títulos, duraciones (seg) y el subgénero.
insert into tracks (titulo, artista, url, duracion_seg, channel_id) values
('Tema 1', 'Artista A', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/01.mp3', 180, (select id from channels where slug='rock-nacional')),
('Tema 2', 'Artista B', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/02.mp3', 210, (select id from channels where slug='rock-nacional')),
('Tema 3', 'Artista C', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/03.mp3', 195, (select id from channels where slug='rock-alternativo')),
('Tema 4', 'Artista D', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/04.mp3', 240, (select id from channels where slug='cumbia-villera')),
('Tema 5', 'Artista E', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/05.mp3', 170, (select id from channels where slug='cumbia-pop')),
('Tema 6', 'Artista F', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/06.mp3', 200, (select id from channels where slug='trap')),
('Tema 7', 'Artista G', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/07.mp3', 220, (select id from channels where slug='house')),
('Tema 8', 'Artista H', 'https://cgvdvkuxjqzcnnsagyvw.supabase.co/storage/v1/object/public/tracks/08.mp3', 185, (select id from channels where slug='local-rock'));

-- Arrancar todos los canales que tengan temas:
select radio_tick_all();

-- Moderador (después de registrarte):
-- update profiles set rol = 'moderador' where apodo = 'TU_APODO';
