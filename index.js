const admin = require("firebase-admin");
const { XMLParser } = require("fast-xml-parser");

const FEED_URL =
  "https://www.aemet.es/documentos_d/eltiempo/prediccion/avisos/rss/CAP_AFAZ770302_RSS.xml";

const AEMET_API_BASE =
  "https://opendata.aemet.es/opendata/api";

const NOVELDA_CODIGO = "03660";

const COLLECTION_AVISOS = "avisos_creados";
const COLLECTION_TIEMPO = "tiempo";
const DOCUMENTO_TIEMPO = "novelda";

if (!process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  throw new Error("Falta FIREBASE_SERVICE_ACCOUNT_JSON");
}

if (!process.env.AEMET_API_KEY) {
  throw new Error("Falta AEMET_API_KEY");
}

const serviceAccount = JSON.parse(
  process.env.FIREBASE_SERVICE_ACCOUNT_JSON
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: "@_",
  removeNSPrefix: true,
  trimValues: true,
});

function asArray(value) {
  if (value == null) return [];
  return Array.isArray(value) ? value : [value];
}

function text(value) {
  if (value == null) return "";

  if (typeof value === "string" || typeof value === "number") {
    return String(value);
  }

  if (typeof value === "object") {
    return String(value["#text"] ?? value.text ?? "");
  }

  return "";
}

function normalise(value) {
  return text(value)
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function severityFromCap(value) {
  const v = normalise(value);

  if (
    v.includes("extreme") ||
    v.includes("red") ||
    v.includes("rojo")
  ) {
    return "rojo";
  }

  if (
    v.includes("severe") ||
    v.includes("orange") ||
    v.includes("naranja")
  ) {
    return "naranja";
  }

  if (
    v.includes("moderate") ||
    v.includes("yellow") ||
    v.includes("amarillo")
  ) {
    return "amarillo";
  }

  return "amarillo";
}

function capField(info, name) {
  const values = asArray(info[name]);

  if (values.length === 0) {
    return "";
  }

  return text(values[0]);
}

async function fetchText(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      "User-Agent": "NoveldaAhora/1.0",
      Accept: "application/rss+xml, application/xml, text/xml, */*",
      ...(options.headers || {}),
    },
  });

  if (!response.ok) {
    throw new Error(
      `HTTP ${response.status} al consultar ${url}`
    );
  }

  return response.text();
}

async function getFeedItems() {
  const xml = await fetchText(FEED_URL);
  const data = parser.parse(xml);

  return asArray(data?.rss?.channel?.item);
}

function getItemLink(item) {
  return text(item.link?.["#text"] ?? item.link);
}

async function parseCap(url) {
  if (!url) {
    return null;
  }

  try {
    const xml = await fetchText(url);
    const data = parser.parse(xml);

    const info = data?.alert?.info;

    if (!info) {
      return null;
    }

    const firstInfo = asArray(info)[0];
    const areas = asArray(firstInfo.area);

    const areaTexts = areas.map((area) =>
      capField(area, "areaDesc")
    );

    return {
      identifier:
        text(data?.alert?.identifier) || url,

      event: capField(firstInfo, "event"),

      headline: capField(firstInfo, "headline"),

      description: capField(firstInfo, "description"),

      instruction: capField(firstInfo, "instruction"),

      severity: capField(firstInfo, "severity"),

      urgency: capField(firstInfo, "urgency"),

      certainty: capField(firstInfo, "certainty"),

      onset: capField(firstInfo, "onset"),

      expires: capField(firstInfo, "expires"),

      areas: areaTexts,

      level: severityFromCap(
        capField(firstInfo, "severity")
      ),

      sourceUrl: url,
    };
  } catch (error) {
    console.warn(
      `No se pudo leer CAP ${url}: ${error.message}`
    );

    return null;
  }
}

function affectsNovelda(cap) {
  if (!cap) {
    return false;
  }

  const haystack = normalise(
    [
      ...(cap.areas || []),
      cap.headline,
      cap.description,
      cap.event,
    ].join(" ")
  );

  return (
    haystack.includes("novelda") ||
    haystack.includes("interior de alicante") ||
    cap.areas.length > 0
  );
}

function documentId(identifier) {
  return identifier
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .slice(0, 500);
}

async function saveCap(cap) {
  if (!cap || !affectsNovelda(cap)) {
    return false;
  }

  const id = documentId(cap.identifier);

  const data = {
    id: id,

    titulo:
      cap.headline ||
      cap.event ||
      "Aviso meteorológico",

    tipo:
      cap.event ||
      "Fenómeno meteorológico adverso",

    nivel:
      cap.level ||
      "amarillo",

    severidad:
      cap.severity ||
      "",

    urgencia:
      cap.urgency ||
      "",

    certeza:
      cap.certainty ||
      "",

    descripcion:
      cap.description ||
      "",

    instrucciones:
      cap.instruction ||
      "",

    zonas:
      cap.areas ||
      [],

    inicio:
      cap.onset ||
      null,

    fin:
      cap.expires ||
      null,

    urlAemet:
      cap.sourceUrl,

    identificadorAemet:
      cap.identifier,

    actualizadoEn:
      admin.firestore.FieldValue.serverTimestamp(),

    activo:
      true,
  };

  await db
    .collection(COLLECTION_AVISOS)
    .doc(id)
    .set(data, { merge: true });

  console.log(
    `Guardado: ${data.titulo} [${data.nivel}]`
  );

  return true;
}

// ============================================================
// TIEMPO AEMET
// ============================================================

async function getAemetPrediction(endpoint) {
  const url =
    `${AEMET_API_BASE}${endpoint}` +
    `?api_key=${encodeURIComponent(process.env.AEMET_API_KEY)}`;

  const responseText = await fetchText(url);

  const metadata = JSON.parse(responseText);

  if (!metadata.datos) {
    throw new Error(
      "AEMET no devolvió la URL de datos"
    );
  }

  const datosText = await fetchText(metadata.datos);

  return JSON.parse(datosText);
}

function extraerTemperaturas(prediccion) {
  const dias = asArray(prediccion);

  return dias.map((dia) => {
    const temperatura = dia.temperatura || {};

    return {
      fecha: dia.fecha || null,

      maxima:
        temperatura.maxima ?? null,

      minima:
        temperatura.minima ?? null,

      madrugada:
        temperatura.dato
          ? asArray(temperatura.dato)
          : [],

      estadoCielo:
        dia.estadoCielo
          ? asArray(dia.estadoCielo)
          : [],

      viento:
        dia.viento
          ? asArray(dia.viento)
          : [],

      humedadRelativa:
        dia.humedadRelativa || null,

      probPrecipitacion:
        dia.probPrecipitacion
          ? asArray(dia.probPrecipitacion)
          : [],
    };
  });
}

async function actualizarTiempo() {
  console.log(
    `Consultando predicción AEMET para Novelda ${NOVELDA_CODIGO}...`
  );

  const diaria = await getAemetPrediction(
    `/prediccion/especifica/municipio/diaria/${NOVELDA_CODIGO}`
  );

  let horaria = null;

  try {
    horaria = await getAemetPrediction(
      `/prediccion/especifica/municipio/horaria/${NOVELDA_CODIGO}`
    );
  } catch (error) {
    console.warn(
      `No se pudo obtener la predicción horaria: ${error.message}`
    );
  }

  const prediccionDiaria = extraerTemperaturas(diaria);

  const data = {
    municipio: "Novelda",
    codigoMunicipio: NOVELDA_CODIGO,

    fuente: "AEMET",

    actualizadoEn:
      admin.firestore.FieldValue.serverTimestamp(),

    diaria: prediccionDiaria,

    horaria: horaria || [],

    activo: true,
  };

  await db
    .collection(COLLECTION_TIEMPO)
    .doc(DOCUMENTO_TIEMPO)
    .set(data);

  console.log(
    `Tiempo de Novelda actualizado. Días: ${prediccionDiaria.length}`
  );
}

// ============================================================
// MAIN
// ============================================================

async function main() {
  console.log("========================================");
  console.log("NOVELDA AHORA - ACTUALIZACIÓN");
  console.log("========================================");

  console.log("");
  console.log("Consultando avisos AEMET...");

  const items = await getFeedItems();

  console.log(
    `Entradas RSS: ${items.length}`
  );

  let saved = 0;

  for (const item of items) {
    const link = getItemLink(item);

    if (!link) {
      continue;
    }

    const cap = await parseCap(link);

    if (cap && await saveCap(cap)) {
      saved++;
    }
  }

  console.log(
    `Avisos guardados/actualizados: ${saved}`
  );

  console.log("");
  console.log("Actualizando tiempo de Novelda...");

  await actualizarTiempo();

  console.log("");
  console.log("========================================");
  console.log("ACTUALIZACIÓN COMPLETADA");
  console.log("========================================");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("");
    console.error("===== ERROR BACKEND =====");
    console.error(error);
    process.exit(1);
  });
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
