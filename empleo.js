
const admin = require("firebase-admin");

const JOOBLE_ENDPOINT = "https://es.jooble.org/api/";
const COLLECTION = "empleo_ofertas";

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
        descripcion: String(job.snippet || "").trim(),
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

buscarOfertas()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("ERROR AL ACTUALIZAR EMPLEO:", error.message);
    process.exit(1);
  });
