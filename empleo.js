
const admin = require("firebase-admin");

const JOOBLE_ENDPOINT = "https://es.jooble.org/api/";
const COLLECTION = "empleo_ofertas";
const TAMANO_LOTE = 400;

const KEYWORDS =
  "reponedor cajero supermercado almacén mozo logística picking limpieza hostelería camarero cocina construcción electricista fontanero industria operario";

if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  throw new Error("Falta FIREBASE_SERVICE_ACCOUNT_JSON");
}

if (!process.env.JOOBLE_API_KEY) {
  throw new Error("Falta JOOBLE_API_KEY");
}

admin.initializeApp({
  credential: admin.credential.cert(
    JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
  ),
});

const db = admin.firestore();

/**
 * Convierte entidades HTML habituales en caracteres normales.
 */
function decodificarEntidades(texto) {
  const entidades = {
    nbsp: " ",
    amp: "&",
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
    rsquo: "'",
    lsquo: "'",
    rdquo: '"',
    ldquo: '"',
    ndash: "-",
    mdash: "-",
    hellip: "...",
    bull: "-",
    euro: "€",
    pound: "£",
    copy: "©",
    reg: "®",
    trade: "™",
    eacute: "é",
    Eacute: "É",
    aacute: "á",
    Aacute: "Á",
    iacute: "í",
    Iacute: "Í",
    oacute: "ó",
    Oacute: "Ó",
    uacute: "ú",
    Uacute: "Ú",
    ntilde: "ñ",
    Ntilde: "Ñ",
    uuml: "ü",
    Uuml: "Ü",
    ordm: "º",
    ordf: "ª",
    iexcl: "¡",
    iquest: "¿",
  };

  return texto.replace(
    /&(#(?:x[0-9a-f]+|[0-9]+)|[a-z][a-z0-9]+);/gi,
    (coincidencia, entidad) => {
      if (entidad.charAt(0) === "#") {
        try {
          const hexadecimal = entidad.charAt(1).toLowerCase() === "x";
          const numero = hexadecimal
            ? parseInt(entidad.slice(2), 16)
            : parseInt(entidad.slice(1), 10);

          if (
            Number.isInteger(numero) &&
            numero > 0 &&
            numero <= 0x10ffff &&
            !(numero >= 0xd800 && numero <= 0xdfff)
          ) {
            return String.fromCodePoint(numero);
          }
        } catch (_) {
          // Conserva la entidad si no se puede interpretar.
        }

        return coincidencia;
      }

      return Object.prototype.hasOwnProperty.call(entidades, entidad)
        ? entidades[entidad]
        : coincidencia;
    }
  );
}

/**
 * Elimina etiquetas HTML y normaliza espacios y saltos de línea.
 */
function limpiarDescripcion(value) {
  let texto = String(value || "");

  // Elimina bloques que no deben mostrarse como contenido.
  texto = texto.replace(
    /<(script|style)\b[^>]*>[\s\S]*?<\/\1\s*>/gi,
    " "
  );

  // Elimina comentarios HTML.
  texto = texto.replace(/<!--[\s\S]*?-->/g, " ");

  // Conserva separaciones entre párrafos y saltos HTML.
  texto = texto.replace(
    /<\s*br\b[^>]*\/?\s*>|<\/\s*(p|div|li|tr|h[1-6])\s*>/gi,
    "\n"
  );

  // Elimina el resto de etiquetas, como <b>, <strong> y <span>.
  texto = texto.replace(/<[^>]*>/g, " ");

  // Decodifica entidades hasta tres veces para casos como &amp;nbsp;.
  for (let i = 0; i < 3; i++) {
    const anterior = texto;
    texto = decodificarEntidades(texto);

    if (texto === anterior) break;
  }

  // Elimina caracteres de control y normaliza espacios.
  texto = texto
    .replace(/\u00a0/g, " ")
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "")
    .replace(/[ \t]+/g, " ")
    .replace(/ *\n */g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();

  return texto;
}

function normalizar(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function esOfertaRelevante(job) {
  const texto = normalizar(
    `${job.title || ""} ${job.snippet || ""}`
  );

  const puestos = [
    "reponedor", "reponedora", "cajero", "cajera",
    "supermercado", "almacen", "mozo", "moza",
    "logistica", "picking", "carretillero", "limpieza",
    "limpiador", "limpiadora", "hosteleria", "camarero",
    "camarera", "cocinero", "cocinera", "construccion",
    "electricista", "fontanero", "fontanera", "operario",
    "operaria", "produccion", "industria", "dependiente",
    "dependienta", "repartidor", "repartidora"
  ];

  return puestos.some((puesto) => texto.includes(puesto));
}

function idSeguro(value) {
  return String(value || "")
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .slice(0, 450);
}

/**
 * Reparación opcional de las descripciones que ya están en Firestore.
 *
 * Para ejecutarla una vez:
 * LIMPIAR_OFERTAS_EXISTENTES=true
 *
 * Procesa lotes de 400 documentos y modifica exclusivamente
 * el campo descripcion.
 */
async function repararOfertasExistentes() {
  console.log("Iniciando revisión de ofertas existentes...");

  let ultimoDocumento = null;
  let revisadas = 0;
  let modificadas = 0;

  while (true) {
    let consulta = db
      .collection(COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(TAMANO_LOTE);

    if (ultimoDocumento) {
      consulta = consulta.startAfter(ultimoDocumento);
    }

    const resultado = await consulta.get();

    if (resultado.empty) break;

    const batch = db.batch();
    let cambiosEnLote = 0;

    for (const documento of resultado.docs) {
      revisadas++;

      const descripcionActual = String(
        documento.get("descripcion") || ""
      );

      const descripcionLimpia = limpiarDescripcion(
        descripcionActual
      );

      if (descripcionActual !== descripcionLimpia) {
        batch.update(documento.ref, {
          descripcion: descripcionLimpia,
        });

        cambiosEnLote++;
      }
    }

    if (cambiosEnLote > 0) {
      await batch.commit();
      modificadas += cambiosEnLote;
    }

    ultimoDocumento = resultado.docs[resultado.docs.length - 1];

    console.log(
      `Revisadas: ${revisadas}. Descripciones corregidas: ${modificadas}.`
    );

    if (resultado.docs.length < TAMANO_LOTE) break;
  }

  console.log(
    `Reparación terminada. Revisadas: ${revisadas}; modificadas: ${modificadas}.`
  );
}

async function buscarOfertas() {
  const response = await fetch(
    JOOBLE_ENDPOINT + encodeURIComponent(process.env.JOOBLE_API_KEY),
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "NoveldaAhora/1.0",
      },
      body: JSON.stringify({
        keywords: KEYWORDS,
        location: "Novelda, Alicante",
        radius: 40,
        page: 1,
        ResultOnPage: 50,
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`Jooble respondió HTTP ${response.status}`);
  }

  const data = await response.json();

  if (!Array.isArray(data.jobs)) {
    throw new Error("La respuesta de Jooble no contiene una lista válida");
  }

  const ofertas = data.jobs.filter(esOfertaRelevante);

  console.log(
    `Jooble devolvió ${data.jobs.length} ofertas; ${ofertas.length} pasan el filtro.`
  );

  const batch = db.batch();
  let guardadas = 0;

  for (const job of ofertas) {
    const url = String(job.link || "").trim();
    const idOrigen = String(job.id || url).trim();

    if (!url || !idOrigen) continue;

    const id = idSeguro(idOrigen);
    if (!id) continue;

    batch.set(
      db.collection(COLLECTION).doc(id),
      {
        id,
        idOrigen,
        titulo: String(job.title || "Oferta de empleo").trim(),
        empresa: String(job.company || "").trim(),
        localidad: String(job.location || "").trim(),
        descripcion: limpiarDescripcion(job.snippet || ""),
        salario: String(job.salary || "").trim(),
        jornada: String(job.type || "").trim(),
        fuente: String(job.source || "Jooble").trim(),
        url,
        fechaPublicacion: String(job.updated || "").trim(),
        activo: true,
        proveedor: "jooble",
        consultadoEn: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    guardadas++;
  }

  if (guardadas > 0) {
    await batch.commit();
  }

  console.log(`Ofertas guardadas o actualizadas: ${guardadas}`);
}

async function ejecutar() {
  // Reparación puntual, activada únicamente mediante una variable de entorno.
  if (
    String(process.env.LIMPIAR_OFERTAS_EXISTENTES || "")
      .toLowerCase() === "true"
  ) {
    await repararOfertasExistentes();
  }

  await buscarOfertas();
}

ejecutar()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("ERROR AL ACTUALIZAR EMPLEO:", error);
    process.exit(1);
  });


