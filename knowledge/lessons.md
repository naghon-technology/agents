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

- **[2026-11-20] Un ejemplo en el prompt de un agente es una plantilla: su defecto se copia en
  todo** — Context: al agente que diseña niveles le di una "receta" de pasaje secreto (un cubículo
  de 2 baldosas con la poción). → Qué pasó: las 5 pociones de vida de 11 niveles quedaron en ese
  cubículo, al lado del camino, y el usuario lo vio como un defecto del juego, no de un nivel. →
  Qué hacer: revisar cada ejemplo del prompt como si fuera a aparecer N veces, porque aparece. Una
  regla de calidad se expresa además como verificación medible (acá: "el cuarto de la poción no
  está en el camino más rápido", medido con el juez), no sólo como ejemplo. (prince)

- **[2026-11-20] Imitar un corpus de referencia: la regla sale de los datos, no del último
  reclamo** — Context: generar niveles al estilo de un juego original. → Qué pasó: arreglé "la
  puerta se ve cortada" con una regla inventada y débil, y volvió a pasar; contar en los 14 niveles
  originales mostraba que 0 de 28 puertas están en la fila de arriba. → Qué hacer: ante una queja
  sobre una instancia, primero contar en la referencia qué hace siempre o nunca, y convertir eso en
  la regla. Un "nunca" sobre N grande vale más que cualquier criterio propio. (prince)

- **[2026-11-20] Medir el costo real de UNA corrida antes de prender algo que se repone solo** —
  Context: botón "nivel al azar" con un nivel siempre pre-diseñado en reserva. → Qué pasó: estimé
  US$ 0,50-1; la primera corrida midió US$ 2,28 y 15 min, y el usuario apagó la función. → Qué
  hacer: con reservas, pregeneración o crons, una corrida real primero y el costo medido a la
  vista antes de dejarlo automático. (prince)

## Frontend / UI

- **[2026-10-28] Un bug visual se REPRODUCE antes de diagnosticarlo** — Context: el cliente
  reportó "no aplica los colores que le pido, ejemplo: pone todo el fondo rojo". Se leyó como "lo
  pinta de rojo sin que se lo pidan" y se empezó a arreglar eso. → Qué pasó: al renderizar el menú
  con la configuración REAL guardada en la base, el fondo era crema con detalles rojos. El usuario
  había pedido fondo rojo y el sistema no podía dárselo — el bug era el opuesto del que se iba a
  arreglar. → Qué hacer: con cualquier reporte visual, generar el artefacto con los datos de
  producción y MIRARLO antes de tocar código. El reporte dice qué molestó, no cuál es la causa; y
  media hora de arreglo en la dirección equivocada cuesta más que un render. (chefiando)

## Verificación

- **[2026-11-13] Un chequeo tiene que medir el EFECTO, no la intención — y tiene que poder
  fallar** — Context: en un solo día aparecieron CUATRO bugs con la misma forma: todo en verde,
  nada roto, y el usuario viendo otra cosa. (1) Diez personas escribieron por WhatsApp y el bot
  les contestó las 31 veces; ninguna se entregó, porque la plataforma no mandaba el teléfono del
  contacto. Durante esa semana el webhook devolvió 200, las colas estaban vacías, el token era
  válido y SIETE chequeos de salud daban OK — ninguno miraba si lo que escribíamos LLEGABA. (2)
  Las respuestas se cortaban a la mitad por el tope de tokens y nadie leía `stop_reason`. (3) Un
  detector de desbordes preguntaba `scrollHeight`, que bajo `overflow:hidden` viene clampeado al
  lienzo: reportaba "sin desbordes" con el pie 250px afuera. (4) Una guardia verificaba que una
  palabra ESTUVIERA en el HTML en vez de que el dato hiciera algo. → Qué hacer: para cada chequeo,
  preguntarse "¿qué entrada lo haría fallar?". Si no hay ninguna, no es un chequeo. Y medir el
  último eslabón, el que toca al usuario: "lo generé" no es "lo entregué", "devolvió 200" no es
  "lo procesó", "la palabra está" no es "el dato se usó". Entre el borde del sistema y la persona
  suele haber un centímetro que nadie mira, y es donde viven los bugs que el cliente reporta y
  nosotros no podemos reproducir. (chefiando) — (5) Un build cuyo chequeo de éxito era "existe
  el `.wasm`" decía "Listo" con el artefacto VIEJO si la compilación fallaba: borrar la salida
  antes de compilar, así el chequeo puede fallar. (prince)

- **[2026-11-13] Cuando el resultado de un modelo sale raro, grepear lo que PEDIMOS antes de
  culpar al modelo** — Context: un usuario reportó como lo más grave del producto que al pedir
  "cambiá sólo X" la imagen volvía con X, Y y Z cambiados. → Qué pasó: el código editaba la foto
  ORIGINAL del usuario y no la imagen mejorada que la persona estaba mirando, así que el modelo
  nunca veía lo que le pedían modificar; y el prompt del cambio incluía igual la receta estética
  completa ("golden lighting, rich saturated colors, crisp focus, blurred background"), o sea que
  la Y y la Z se las pedíamos nosotros. Es la tercera vez en el mismo repo: el humo de los videos
  estaba escrito en nuestro prompt, y los calcos de idioma venían del vocabulario del prompt. →
  Qué hacer: ante una salida rara de un modelo, leer el prompt COMPLETO y verificar sobre qué
  entrada corre, antes de tocar parámetros o cambiar de modelo. Y para una herramienta de edición
  iterativa, la pregunta que lo resuelve casi siempre: ¿está editando la última versión ENTREGADA,
  o re-generando desde el principio? (chefiando)


- **[2026-10-30] Mirar N artefactos con la configuración POR DEFECTO no prueba que el PEDIDO
  funcione** — Context: al cambiar el motor que dibuja los cardápios se verificó renderizando los
  15 negocios reales y mirándolos, cuatro rondas, arreglando cada defecto visible. → Qué pasó: al
  día siguiente el cliente encontró tres bugs en veinte minutos y los tres eran el mismo ciclo:
  *pido un cambio, el sistema dice que sí, llega lo mismo*. Los quince renders habían salido todos
  con la configuración por defecto, así que ninguno ejercitaba una sola palanca del feature. →
  Qué hacer: cuando el valor del feature es "pedís algo y lo ves", la aserción no es que la salida
  esté bien sino que **CAMBIE** respecto de antes del pedido (`assert.notEqual(despues, antes)`),
  una por palanca. Es barato, no necesita saber cómo tiene que quedar, y es lo único que ve esta
  familia entera de bugs. Mirar el artefacto sigue haciendo falta: encuentra otras cosas, no éstas.
  (chefiando)

- **[2026-10-30] Una regla defensiva que decide NO mostrar un dato se mide antes de dejarla** —
  Context: con un precio de varios importes ("S/95 entera | S/12 porción") el renderer no mostraba
  ninguno, con un razonamiento correcto: elegir uno y presentarlo como *el* precio sería mentirle
  al cliente final. → Qué pasó: medido contra producción, el 24% de los platos tenía varios
  importes, así que a una cuarta parte del catálogo le quedaba la columna del precio VACÍA — el
  dato que el usuario había cargado, escondido. El razonamiento seguía siendo correcto y el
  resultado era malo igual. → Qué hacer: toda regla del tipo "ante la duda no muestro nada" tiene
  que venir con el número de cuántas veces se dispara; si es frecuente, casi siempre existe una
  tercera opción que respeta el razonamiento ("a partir de S/12" dice que es el piso, no elige un
  precio). Un default conservador que descarta datos en silencio es una decisión de producto
  disfrazada de prudencia técnica. (chefiando)

- **[2026-10-30] Un número que medí ayer no es un número: se vuelve a medir** — Context: se iba a
  construir sobre un hallazgo propio de la víspera ("4 de 15 negocios tienen platos sin precio").
  → Qué pasó: al medirlo de nuevo antes de escribir el fix, eran CERO: lo que se había contado
  como "falta el precio" era en realidad el problema de los varios importes, que se veía igual
  desde afuera. El arreglo habría quedado apuntando a un problema inexistente. → Qué hacer: una
  medición vieja se trata como una hipótesis, igual que la deuda conocida; correr la consulta de
  nuevo cuesta dos minutos y es lo que separa arreglar de parecer que se arregla. (chefiando)

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

- **[2026-10-30] Al cambiar de motor, cada parámetro que el viejo respetaba se vuelve a cablear a
  mano** — Context: se reemplazó un renderer propio por otro (SVG escrito a mano → Chromium sobre
  HTML) y se verificó que las piezas salieran bien. → Qué pasó: el motor nuevo armaba su tema con
  un hash del nombre y NUNCA miraba la paleta que el pipeline venía calculando, así que durante un
  día ningún usuario pudo cambiarle el color a su pieza — y el sistema contestaba "listo, lo
  apliqué" sin mentir, porque la herramienta que guardaba el color devolvía OK. La mentira la
  fabricaba el paso siguiente. → Qué hacer: un cambio de motor no es una migración de salida sino
  de ENTRADAS: listar todos los parámetros que el motor viejo aceptaba y verificar uno por uno que
  el nuevo los lee; los que no, no fallan — se ignoran en silencio. Es un caso particular de la
  lección del CABLEADO y se testea igual, contra el fuente. (chefiando)

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
