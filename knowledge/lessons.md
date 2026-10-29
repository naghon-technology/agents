# Lessons learned (cross-project)

Already-solved mistakes and patterns that worked, shared across all projects. Before
fighting something, check whether it's already here.

Format for each entry:
- **[date] Short title** — Context → What happened → What to do / avoid. (project where discovered)

---

## Deploy / Infra

- **[seed] Vercel: secrets and models** — Never hardcode secrets or put them in
  `NEXT_PUBLIC_*`. With Vercel AI Gateway, verify the real model catalog
  (`curl https://ai-gateway.vercel.sh/v1/models`) before pinning a model string; don't
  trust IDs from memory. (aiforma)

- **[2026-10-13] Un backup sin watchdog externo no es un backup** — Context: la base de
  Chatwoot (6.745 mensajes reales) vivía en un volumen de una sola VM; el bucket y su
  lifecycle estaban creados desde hacía meses y el script nunca se había escrito, así que la
  infra PARECÍA resuelta. → Dos reglas: (1) el que vigila el backup tiene que ser OTRO
  proceso — un script que se alerta a sí mismo cubre "corrí y fallé" pero nunca "dejé de
  correr", que es la falla más común y la única totalmente silenciosa; acá el script deja una
  marca con fecha y la app la lee como un chequeo de salud más, así la marca vieja delata el
  timer muerto. (2) Un backup que nunca se restauró es una hipótesis: restaurarlo una vez,
  contra la MISMA imagen que usa producción (con `postgres:16` pelado el dump de Chatwoot da
  ~30 errores que parecen corrupción y son la extensión `vector` faltante). (chefiando)

- **[2026-10-13] Leer un secreto con un CLI que loguea y escribirlo a un `.env`** — Context:
  `rails runner "puts secret"` escupe WARN/INFO mezclados con el valor; un `tail -c 200` metió
  el log entero en el `.env` de producción. → Qué pasó: el archivo quedó con líneas multilínea
  inválidas, `docker compose` no pudo leerlo y **no recreó el contenedor — exit 0 y el deploy
  no se aplicó, en silencio**. Además el secreto quedó expuesto al depurarlo y hubo que
  rotarlo. → Qué hacer: delimitadores (`puts "<<<#{x}>>>"` + `sed -n "s/.*<<<\(.*\)>>>.*/\1/p"`),
  validar el largo esperado ANTES de escribir, y después
  `grep -cvE "^[A-Za-z_][A-Za-z0-9_]*=|^#|^$" .env` (tiene que dar 0). Un deploy que devuelve 0
  no prueba que se aplicó: verificar el código DENTRO del contenedor. (chefiando)

- **[2026-10-13] Activar una verificación que puede cortar TODO el tráfico va en dos pasos** —
  Context: al empezar a validar la firma HMAC de los webhooks, si el secreto configurado no
  fuera el que usa el emisor, el bot rechazaría el 100% y el síntoma —silencio— tarda horas en
  notarse. → Qué hacer: desplegar primero en modo observación (contar y alertar sin rechazar),
  confirmar con tráfico REAL que valida, y recién ahí poner el flag en exigente. Dejar un
  chequeo de salud que cuente válidas/inválidas: ningún test puede saber qué manda la versión
  del emisor que está corriendo hoy. (chefiando)

## AI / Agents

- **[seed] Voice agents (Retell)** — Watch latency, interruption handling, and silences
  (configurable silence cutoff), plus conversational fallbacks. Agent/LLM IDs are not
  changed by hand without syncing. (aiforma)

- **[2026-07-24] Orquestación: no pisar trabajo entre agentes (responsabilidad del orquestador)** — Context: se corrieron agentes en paralelo sobre el MISMO working tree y un `git add -A` de un commit barrió cambios sin commitear de otro agente hacia el commit equivocado. → Qué hacer: la coordinación es del orquestador, NUNCA del usuario. Aislar cada agente que ESCRIBE en su propio worktree/rama; nunca `git add -A` si puede haber trabajo ajeno en curso (agregar solo los archivos propios, explícitos); `git status` antes de cada commit para no llevarse lo que no es tuyo. Si algo sale mal en la coordinación de subagentes, es problema del que orquesta, no del usuario. (chefiando)

## Frontend / UI

- **[2026-10-28] Un bug visual se REPRODUCE antes de diagnosticarlo** — Context: el cliente
  reportó "no aplica los colores que le pido, ejemplo: pone todo el fondo rojo". Se leyó como "lo
  pinta de rojo sin que se lo pidan" y se empezó a arreglar eso. → Qué pasó: al renderizar el menú
  con la configuración REAL guardada en la base, el fondo era crema con detalles rojos. El usuario
  había pedido fondo rojo y el sistema no podía dárselo — el bug era el opuesto del que se iba a
  arreglar. → Qué hacer: con cualquier reporte visual, generar el artefacto con los datos de
  producción y MIRARLO antes de tocar código. El reporte dice qué molestó, no cuál es la causa; y
  media hora de arreglo en la dirección equivocada cuesta más que un render. (chefiando)

## Seguridad

- **[2026-10-28] Un hallazgo automático de seguridad se verifica claim por claim** — Context: una
  revisión automática marcó SSRF en una dependencia de terceros y propuso dos arreglos: resolver
  el DNS antes de cada hop, y normalizar las IPv4 mapeadas agregando `::ffff:0:0/96` al blocklist.
  → Qué pasó: el primero era real y grave (un NOMBRE que resuelve a 127.0.0.1 o a 169.254.169.254
  atravesaba el filtro entero, verificado con `localtest.me` y `nip.io`). El segundo era
  incorrecto: medido en Node, `BlockList` YA entiende las IPv4 mapeadas, y esa subred habría
  bloqueado direcciones públicas legítimas como `::ffff:8.8.8.8`. → Qué hacer: reproducir cada
  afirmación —la vulnerabilidad Y el arreglo propuesto— con un script de cuatro líneas antes de
  aplicar nada. Un arreglo sugerido y no medido puede romper tráfico legítimo, que es un incidente
  peor que el que se quería evitar. Y si el código es de terceros con lockfile: el parche se
  pierde en el próximo update, así que se firma, se fecha y se anota dónde revisarlo. (chefiando)

## Backend / Data

- **[2026-10-13] Cuando el bug es el CABLEADO, el test de la función pasa en verde** — Context:
  tres veces en el mismo repo falló algo perfectamente implementado y mal conectado: tools
  declaradas que nunca llegaban al modelo, detección de intents que no se llamaba en el camino
  de los audios, y un guardia de duplicados enchufado sólo en la mitad barata. En los tres
  casos había tests de la lógica y estaban verdes. → Qué hacer: cuando lo que puede fallar es
  DÓNDE se llama algo, el test se escribe contra el FUENTE (`readFileSync` del módulo +
  aserciones sobre la presencia y el orden de las llamadas). Feo, y es lo único que ve ese
  error. (chefiando)

- **[2026-10-28] Una cadena nueva se testea desde donde NACE el dato, no desde donde se consume** —
  Context: se construyó "foto por plato" en el cardápio —matcheo por palabras, miniaturas, collage,
  reglas de cobertura— con tests de unidad en verde, y no funcionaba para NINGÚN negocio. → Qué
  pasó: la foto que mandaba el usuario se le pasaba al modelo para que la viera y se descartaba;
  `saveAsset` sólo se llamaba al GENERAR. El productor del dato no existía, así que la tabla que
  el feature consulta estaba vacía. Ningún test de unidad puede ver eso: `fotosDelMenu` estaba
  bien, `fotoPara` estaba bien, y un eslabón que no existe no tiene función que testear. → Qué
  hacer: ANTES de escribir el consumidor, consultar producción y confirmar que el dato llega de
  verdad (`select count(*) ... where <la condición que el feature usa>`); si da cero, el feature
  no existe todavía por más código que tenga. Es el hermano de la lección del CABLEADO: aquélla
  es "lo llamo desde el lugar equivocado", ésta es "nadie lo produce". (chefiando)

---

## How to add lessons
Use `/retro` at the end of a task. Only what's useful in MORE than one project goes here.
Anything project-specific goes to its own `CLAUDE.md`.
