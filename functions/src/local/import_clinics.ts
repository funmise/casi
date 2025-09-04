import * as admin from "firebase-admin";
import * as XLSX from "xlsx";
import * as path from "path";

const serviceAccount = require(path.resolve(__dirname, "../../serviceAccountKey.json"));

try {
  admin.app();
} catch {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
}
const db = admin.firestore();

type RawRow = Record<string, any>;

/**
 *
 * @param v
 */
function toInt(v: any): number | undefined {
  if (v === null || v === undefined || v === "") return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? Math.round(n) : undefined;
}

// pick the first non-empty value among possible header names
const pick = (r: RawRow, keys: string[]) =>
  keys.map((k) => (r[k] ?? "").toString().trim()).find((v) => v) ?? "";

// find which row is the true header (handles sheets with a banner row above)
/**
 *
 * @param ws
 */
function findHeaderRow(ws: XLSX.WorkSheet): { headerRow: string[]; startRow: number } | null {
  const aoa = XLSX.utils.sheet_to_json<any[]>(ws, { header: 1, defval: "" }) as any[][];
  const wanted = /^(organization|clinic\s*name|name)$/i;

  for (let i = 0; i < Math.min(10, aoa.length); i++) {
    const row = aoa[i].map((c) => (typeof c === "string" ? c.trim() : c));
    if (row.some((c) => typeof c === "string" && wanted.test(c))) {
      // normalize empty headers to unique placeholders so xlsx won't drop columns
      const headerRow = row.map((h, idx) => (h && String(h).trim()) || `col_${idx}`);
      return { headerRow, startRow: i + 1 };
    }
  }
  return null;
}

/**
 *
 */
async function run() {
  const file = process.argv[2] || path.join(__dirname, "../data/clinics.xlsx");
  const wb = XLSX.readFile(file);

  let totalParsed = 0;
  let imported = 0;

  let batch = db.batch();
  let opsInBatch = 0;

  for (const sheetName of wb.SheetNames) {
    const ws = wb.Sheets[sheetName];

    const headerInfo = findHeaderRow(ws);
    if (!headerInfo) {
      console.log(`[${sheetName}] no header row found (skipping)`);
      continue;
    }

    const { headerRow, startRow } = headerInfo;

    // Re-read as objects using the detected header row
    const rows = XLSX.utils.sheet_to_json<RawRow>(ws, {
      header: headerRow,
      range: startRow,
      defval: "",
    });

    let sheetImported = 0;
    totalParsed += rows.length;

    for (const r of rows) {
      const name = pick(r, ["Name", "Clinic name", "Organization"]);
      if (!name) continue;
      if (/^see website/i.test(name)) continue; // skip banner-like rows

      const city = pick(r, ["City"]) || undefined;
      const province =
        pick(r, ["Province", "Province/Territory"]) || sheetName.trim() || undefined;
      const status = (pick(r, ["Status"]) || "active").toLowerCase();

      const avgDogsStr = pick(r, ["AvgDogsPerWeek", "Avg Dogs/Week", "Avg Dogs per Week"]);
      const avgDogsPerWeek = toInt(avgDogsStr);

      const ref = db.collection("clinics").doc();
      batch.set(ref, {
        name,
        nameLower: name.toLowerCase(),
        province,
        city,
        status,
        ...(avgDogsPerWeek !== undefined ? { avgDogsPerWeek } : {}),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      imported++;
      sheetImported++;
      opsInBatch++;

      // stay under Firestore's 500-ops-per-batch limit
      if (opsInBatch >= 450) {
        await batch.commit();
        batch = db.batch();
        opsInBatch = 0;
      }
    }

    console.log(`[${sheetName}] parsed ${rows.length}, imported ${sheetImported}`);
  }

  if (opsInBatch > 0) {
    await batch.commit();
  }

  console.log(`Parsed ${totalParsed} rows from ${file}.`);
  console.log(`Done. Imported ${imported} clinics.`);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
