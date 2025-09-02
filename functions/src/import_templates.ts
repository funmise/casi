// functions/src/import_templates.ts
import * as admin from "firebase-admin";
import * as path from "path";

const serviceAccount = require(path.resolve(__dirname, "../serviceAccountKey.json"));

try {
  admin.app();
} catch {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
}

const db = admin.firestore();

// ---------------------------------------------
// Types
// ---------------------------------------------
export const TEMPLATE_ORDER = [
  "dog_caseload",
  "echinococcus",
  "mrsa_mrsp",
  "salmonella",
  "gi",
  "borrelia",
  "vector",
  "leptospira",
  "brucella",
  "distemper",
  "influenza",
  "parvovirus",
  "notes_pathogens",
  "vector_snap", // diagnostics
  "fecal_float", // diagnostics
  "parvovirus_snap", // diagnostics
  "notes_tests",
  "notes_final",
] as const;

type PageId = typeof TEMPLATE_ORDER[number];

type booleanInput = { id: string; type: "boolean"; label: string };
type IntInput = {
  id: string;
  type: "int";
  label: string;
  min?: number;
  max?: number;
  lockIf?: Record<string, unknown>;
};
type EnumInput = {
  id: string;
  type: "enum";
  label: string;
  options: string[];
  lockIf?: Record<string, unknown>;
};
type MultilineInput = {
  id: string;
  type: "multiline";
  label: string;
  maxLength?: number;
  lockIf?: Record<string, unknown>;
};

type InputDef = booleanInput | IntInput | EnumInput | MultilineInput;

type PageDoc = {
  kind: "census" | "pathogen" | "diagnostic" | "notes";
  title: string;
  prompt?: string;
  inputs: InputDef[];
};

// ---------------------------------------------
// Page definitions (v1)
// ---------------------------------------------
const pathogen = (pathogen: string): PageDoc => ({
  kind: "pathogen",
  title: pathogen,
  inputs: [
    {
      id: "diagnosed", type: "boolean",
      label: `Have you or your clinic diagnosed ${pathogen} in a dog ` +
        "during the reporting quarter?",
    },
    {
      id: "count_confirmed",
      type: "int",
      label: "Number of confirmed cases (lab-based)",
      min: 0,
      max: 500,
      lockIf: { diagnosed: false },
    },
    {
      id: "count_suspected",
      type: "int",
      label: "Number of suspected cases (clinical suspicion)",
      min: 0,
      max: 500,
      lockIf: { diagnosed: false },
    },
    {
      id: "relative_trend",
      type: "enum",
      label: "Relative frequency compared to same quarter last year?",
      options: ["increasing", "same", "decreasing"],
    },
  ],
});

const diagnostic = (
  test: string,
): PageDoc => ({
  kind: "diagnostic",
  title: test,
  inputs: [
    {
      id: "performed", type: "boolean",
      label: `Have you or your clinic performed ${test} test during the reporting quarter?`,
    },
    {
      id: "count",
      type: "int",
      label: "Number of tests this quarter",
      min: 0,
      max: 500,
      lockIf: { performed: false },
    },
    {
      id: "relative_trend",
      type: "enum",
      label: "Relative use compared to same quarter last year",
      options: ["increasing", "same", "decreasing"],
    },
  ],
});

const PAGES_V1: Record<PageId, PageDoc> = {
  // --- Dogs Census ---
  dog_caseload: {
    kind: "census",
    title: "Dog Census",
    inputs: [
      {
        id: "count",
        type: "int",
        label: "On average, how many dogs did you see at your clinic every week in this reporting quarter?",
        min: 0,
        max: 100,
      },

      {
        id: "relative_trend",
        type: "enum",
        label: "Relative weekly caseload compared to same quarter last year?",
        options: ["increasing", "same", "decreasing"],
        lockIf: { diagnosed: false },
      },

    ],
  },


  // --- Pathogens ---
  echinococcus: pathogen("Echinococcus (multilocularis or granulosus)"),
  mrsa_mrsp: pathogen("MRSA/MRSP"),
  salmonella: pathogen("Salmonella (i.e. human important serovars)"),
  gi: pathogen("other GI pathogens (i.e. Campylobacter E. Coli, etc)"),
  borrelia: pathogen("Borrelia burgdorferi (Lyme disease)"),
  vector: pathogen("other vector-borne diseases (i.e. Ehrlichia spp., Anaplasma spp., etc)"),
  leptospira: pathogen("Leptospira spp"),
  brucella: pathogen("Brucella canis"),
  distemper: pathogen("Distemper"),
  influenza: pathogen("Canine Influenza"),
  parvovirus: pathogen("Parvovirus"),

  // --- Diagnostics ---
  vector_snap: diagnostic("Vector-borne SNAP (i.e. in-house 4DX)"),
  fecal_float: diagnostic("Fecal floatation (in house)"),
  parvovirus_snap: diagnostic("Parvovirus SNAP"),

  // --- Notes pages ---
  notes_pathogens: {
    kind: "notes",
    title: "Notes on pathogens/diseases",
    inputs: [
      {
        id: "notes",
        type: "multiline",
        label:
          "Use this space to provide any important notes about specific cases (please specify things" +
          " like travel history, unusual presentation, etc)",
        maxLength: 4000,
      },
    ],
  },
  notes_tests: {
    kind: "notes",
    title: "Notes on tests",
    inputs: [
      {
        id: "notes",
        type: "multiline",
        label:
          "Use this space to make any comments on the testing that you had done this quarter (please specify)",
        maxLength: 4000,
      },
    ],
  },
  notes_final: {
    kind: "notes",
    title: "Final notes",
    inputs: [
      {
        id: "notes",
        type: "multiline",
        label:
          "Do you want to report any other strange clinical presentation, pathogen or disease that you have" +
          " diagnosed during the quarter you are reporting for (i.e. new, or unusual presentation)? Please " +
          "use the following comment box to detail this case (maintain anonymity of the client when" +
          " discussing this case).",
        maxLength: 4000,
      },
    ],
  },
};

// ---------------------------------------------
// Seed the template (header + per-page docs)
// ---------------------------------------------
/**
 *
 * @param versionId
 */
async function seedTemplate(versionId: string) {
  const rootRef = db.collection("survey_templates").doc(versionId);

  await rootRef.set(
    {
      title: "Quarterly Survey",
      subtitle: "Report for the previous reporting quarter",
      order: TEMPLATE_ORDER,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const pagesRef = rootRef.collection("pages");
  const batch = db.bulkWriter();

  TEMPLATE_ORDER.forEach((pid: PageId) => {
    const page = PAGES_V1[pid];
    batch.set(pagesRef.doc(pid), page, { merge: true });
  });

  await batch.close();
  console.log(`✓ Template ${versionId} seeded (${TEMPLATE_ORDER.length} pages).`);
}

// ---------------------------------------------
// Seed the quarter "instance" doc
// ---------------------------------------------
/**
 *
 * @param quarterId
 * @param opensAtISO
 * @param closesAtISO
 * @param templateVersion
 */
async function seedInstance(
  quarterId: string,
  opensAtISO: string,
  closesAtISO: string,
  templateVersion: string
) {
  const opens = new Date(opensAtISO);
  const closes = new Date(closesAtISO);
  if (isNaN(opens.getTime()) || isNaN(closes.getTime())) {
    throw new Error("opensAtISO/closesAtISO must be valid ISO-8601 strings");
  }

  const ref = db.collection("survey_instances").doc(quarterId);
  await ref.set(
    {
      quarter: quarterId,
      opensAt: opens,
      closesAt: closes,
      templateVersion,
      isActive: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  console.log(`✓ Instance ${quarterId} -> template ${templateVersion} seeded.`);
}

// // ---------------------------------------------
// // CLI entry
// // Usage:
// //   npm run import:templates -- v1 2025-Q3 2025-10-01T00:00:00Z 2025-10-31T23:59:59Z
// // ---------------------------------------------
// (async () => {
//   const [, , versionId, quarterId, opensISO, closesISO] = process.argv;

//   if (!versionId || !quarterId || !opensISO || !closesISO) {
//     console.error(
//       "Usage: ts-node src/import_templates.ts <versionId> <quarterId> <opensAtISO> <closesAtISO>"
//     );
//     process.exit(1);
//   }

//   await seedTemplate(versionId);
//   await seedInstance(quarterId, opensISO, closesISO, versionId);

//   process.exit(0);
// })();
// ---------------------------------------------
// CLI entry
// Usage:
//   # Seed only the template
//   ts-node src/import_templates.ts v1
//
//   # Seed template + instance
//   ts-node src/import_templates.ts v1 2025-Q3 2025-10-01T00:00:00Z 2025-12-31T23:59:59Z
// ---------------------------------------------
(async () => {
  const [, , versionId, quarterId, opensISO, closesISO] = process.argv;

  if (!versionId) {
    console.error("Usage: ts-node src/import_templates.ts <versionId> [quarterId opensAtISO closesAtISO]");
    process.exit(1);
  }

  // Always seed the template
  await seedTemplate(versionId);

  // If extra args given, seed instance as well
  if (quarterId && opensISO && closesISO) {
    await seedInstance(quarterId, opensISO, closesISO, versionId);
  } else {
    console.log(`✓ Only template ${versionId} seeded (no instance).`);
  }

  process.exit(0);
})();

