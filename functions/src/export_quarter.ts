import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import * as crypto from 'crypto';
import archiver = require('archiver');
import zipEncryptable = require('archiver-zip-encryptable');
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { google } from 'googleapis';
import { Readable } from 'stream';

// ───────────────────────────────────────────────────────────────────────────────
// config
// ───────────────────────────────────────────────────────────────────────────────
const EXPORT_SECRETS = [
    'DRIVE_CLIENT_ID',
    'DRIVE_CLIENT_SECRET',
    'DRIVE_REFRESH_TOKEN',
    'DRIVE_RAW_FOLDER_ID',
    'DRIVE_ZIP_FOLDER_ID',
    'EXPORT_CSV_PASSWORD',
    'EXPORT_SALT',
];

function getCfg(): any {
    try {
        return functions.config() || {};
    } catch {
        return {};
    }
}
const CFG = getCfg();

// Drive OAuth (personal Google account). Accept from drive.* OR export.drive_*
const DRIVE_CLIENT_ID =
    CFG.drive?.client_id || process.env.DRIVE_CLIENT_ID || CFG.export?.drive_client_id || '';
const DRIVE_CLIENT_SECRET =
    CFG.drive?.client_secret || process.env.DRIVE_CLIENT_SECRET || CFG.export?.drive_client_secret || '';
const DRIVE_REFRESH_TOKEN =
    CFG.drive?.refresh_token || process.env.DRIVE_REFRESH_TOKEN || CFG.export?.drive_refresh_token || '';

const RAW_FOLDER_ID =
    CFG.drive?.raw_folder_id || process.env.DRIVE_RAW_FOLDER_ID || CFG.export?.drive_raw_folder_id || '';
const ZIP_FOLDER_ID =
    CFG.drive?.zip_folder_id || process.env.DRIVE_ZIP_FOLDER_ID || CFG.export?.drive_zip_folder_id || '';

// Export settings
const ZIP_PASSWORD = CFG.export?.csv_password || process.env.EXPORT_CSV_PASSWORD || '';
const ANON_SALT = CFG.export?.salt || process.env.EXPORT_SALT || '';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// ───────────────────────────────────────────────────────────────────────────────
// google drive oauth client (personal drive)
// ───────────────────────────────────────────────────────────────────────────────

function drive() {
    if (!DRIVE_CLIENT_ID || !DRIVE_CLIENT_SECRET || !DRIVE_REFRESH_TOKEN) {
        throw new Error('Missing drive.* OAuth config (client_id, client_secret, refresh_token).');
    }
    const oAuth2 = new google.auth.OAuth2(DRIVE_CLIENT_ID, DRIVE_CLIENT_SECRET);
    oAuth2.setCredentials({ refresh_token: DRIVE_REFRESH_TOKEN });
    return google.drive({ version: 'v3', auth: oAuth2 });
}

// Turn Buffer/string into a Readable stream (Drive multipart needs .pipe()).
function toStream(data: Buffer | string): NodeJS.ReadableStream {
    return typeof data === 'string' ? Readable.from([data]) : Readable.from(data);
}

// ───────────────────────────────────────────────────────────────────────────────
// csv helpers
// ───────────────────────────────────────────────────────────────────────────────

/** Columns in the **data** CSV (NO identifying clinic info here). */
const BASE_DATA_COLUMNS = [
    'anonId',
    'quarterId',
    'submittedAt',
    'templateVersion',
] as const;
type BaseCols = (typeof BASE_DATA_COLUMNS)[number];

function csvEscape(v: unknown): string {
    if (v === null || v === undefined) return '';
    const s = String(v);
    return s.includes('"') || s.includes(',') || s.includes('\n') || s.includes('\r')
        ? `"${s.replace(/"/g, '""')}"`
        : s;
}
export function csvLine(fields: (string | number | boolean | null | undefined)[]) {
    return fields.map(csvEscape).join(',') + '\n';
}
function hmacAnonId(uid: string, quarterId: string) {
    if (!ANON_SALT) throw new Error('Missing export.salt');
    const h = crypto.createHmac('sha256', ANON_SALT);
    h.update(`${uid}:${quarterId}`);
    return h.digest('base64url').replace(/[^a-zA-Z0-9]/g, '').slice(0, 12);
}

// ───────────────────────────────────────────────────────────────────────────────
// template → answer keys (pageId.fieldId)
// ───────────────────────────────────────────────────────────────────────────────

async function fetchAnswerKeysForTemplate(version: string) {
    const tmplRef = db.collection('survey_templates').doc(version);
    const tmplSnap = await tmplRef.get();
    if (!tmplSnap.exists) return [];
    const order = (tmplSnap.get('order') as string[]) ?? [];
    const keys: string[] = [];
    for (const pageId of order) {
        const pageSnap = await tmplRef.collection('pages').doc(pageId).get();
        if (!pageSnap.exists) continue;
        const inputs = (pageSnap.get('inputs') as unknown[]) ?? [];
        for (const raw of inputs) {
            if (typeof raw !== 'object' || raw === null) continue;
            const id = (raw as any).id;
            if (!id) continue;
            keys.push(`${pageId}.${String(id)}`);
        }
    }
    return keys;
}

export async function ensureQuarterHeader(quarterId: string, templateVersion: string) {
    // Persist only the DATA header (identifying fields are in key file and not part of this header)
    const docRef = db.collection('exports').doc(quarterId);
    const snap = await docRef.get();
    if (snap.exists) {
        const header = snap.get('header') as string[] | undefined;
        if (header?.length) return header;
    }
    const answerKeys = await fetchAnswerKeysForTemplate(templateVersion);
    const header = [...BASE_DATA_COLUMNS, ...answerKeys];
    await docRef.set(
        { header, templateVersion, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
    );
    return header;
}

// ───────────────────────────────────────────────────────────────────────────────
// flatten answers
// ───────────────────────────────────────────────────────────────────────────────

function flattenAnswers(answers: any) {
    const out: Record<string, string | number | boolean | null> = {};
    if (!answers || typeof answers !== 'object') return out;
    for (const [pageId, pageVal] of Object.entries(answers)) {
        if (typeof pageVal !== 'object' || pageVal === null) continue;
        for (const [fieldId, value] of Object.entries(pageVal as Record<string, any>)) {
            out[`${pageId}.${fieldId}`] = value as any;
        }
    }
    return out;
}

// ───────────────────────────────────────────────────────────────────────────────
// enrollment + clinic
// ───────────────────────────────────────────────────────────────────────────────

async function fetchClinicEnvelope(uid: string) {
    const enrSnap = await db
        .collection('users')
        .doc(uid)
        .collection('enrollments')
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();

    let clinicId = '',
        clinicName = '';
    if (!enrSnap.empty) {
        const d = enrSnap.docs[0];
        clinicId = (d.get('clinicId') as string) ?? '';
        clinicName = (d.get('clinicName') as string) ?? '';
    }

    let clinicProvince = '',
        clinicCity = '';
    if (clinicId) {
        const c = await db.collection('clinics').doc(clinicId).get();
        if (c.exists) {
            clinicProvince = (c.get('province') as string) ?? '';
            clinicCity = (c.get('city') as string) ?? '';
            if (!clinicName) clinicName = (c.get('name') as string) ?? '';
        }
    }
    return { clinicId, clinicName, clinicProvince, clinicCity };
}

// ───────────────────────────────────────────────────────────────────────────────
// row builders
// ───────────────────────────────────────────────────────────────────────────────

type RowBuild = {
    dataRow: Record<string, string | number | boolean | null>;
    mappingRow: {
        anonId: string;
        uid: string;
        email: string;
        quarterId: string;
        clinicId: string;
        clinicName: string;
        clinicProvince: string;
        clinicCity: string;
    };
    header: string[];
};

export async function buildRowsForDoc(
    uid: string,
    email: string,
    quarterId: string,
    templateVersion: string,
    submittedAt: Date | null,
    answers: any,
): Promise<RowBuild> {
    const anonId = hmacAnonId(uid, quarterId);
    const clinic = await fetchClinicEnvelope(uid);
    const header = await ensureQuarterHeader(quarterId, templateVersion);
    const flat = flattenAnswers(answers);

    // DATA row — no identifying clinic info
    const dict: Record<string, string | number | boolean | null> = {};
    for (const col of header) {
        switch (col as BaseCols | string) {
            case 'anonId':
                dict[col] = anonId;
                break;
            case 'quarterId':
                dict[col] = quarterId;
                break;
            case 'submittedAt':
                dict[col] = submittedAt ? submittedAt.toISOString() : '';
                break;
            case 'templateVersion':
                dict[col] = templateVersion;
                break;
            default:
                dict[col] = flat[col] ?? '';
        }
    }

    // KEY row — contains identifying mapping + clinic info
    const mappingRow = {
        anonId,
        uid,
        email,
        quarterId,
        clinicId: clinic.clinicId,
        clinicName: clinic.clinicName,
        clinicProvince: clinic.clinicProvince,
        clinicCity: clinic.clinicCity,
    };

    return { dataRow: dict, mappingRow, header };
}

export function namesForQuarter(quarterId: string) {
    const dataCsv = `CASI_${quarterId}_data.csv`;
    const keyCsv = `CASI_${quarterId}_key.csv`;
    const dataZip = `CASI_${quarterId}_data.zip`;
    const keyZip = `CASI_${quarterId}_key.zip`;
    return { dataCsv, keyCsv, dataZip, keyZip };
}

// ───────────────────────────────────────────────────────────────────────────────
// zip helper (AES-256)
// ───────────────────────────────────────────────────────────────────────────────

// Guard: register the plugin only once per process.
let ZIP_FORMAT_REGISTERED = false;
function ensureZipFormatRegistered() {
    if (ZIP_FORMAT_REGISTERED) return;
    try {
        // @ts-ignore
        archiver.registerFormat('zip-encryptable', zipEncryptable);
    } catch (e: any) {
        if (!String(e?.message || e).includes('already registered')) throw e;
    }
    ZIP_FORMAT_REGISTERED = true;
}

async function zipCsv(innerName: string, csvContent: string, password: string) {
    if (!ZIP_PASSWORD) throw new Error('Missing export.csv_password');
    ensureZipFormatRegistered();

    return await new Promise<Buffer>((resolve, reject) => {
        const chunks: Buffer[] = [];
        const archive = archiver.create('zip-encryptable', {
            zlib: { level: 9 },
            encryptionMethod: 'aes256',
            password,
        } as any);
        archive.on('warning', reject);
        archive.on('error', reject);
        archive.on('data', (d: any) => chunks.push(Buffer.isBuffer(d) ? d : Buffer.from(d)));
        archive.on('end', () => resolve(Buffer.concat(chunks)));
        archive.append(csvContent, { name: innerName });
        archive.finalize().catch(reject);
    });
}

// ───────────────────────────────────────────────────────────────────────────────
// Drive helpers (My Drive; no shared drives)
// ───────────────────────────────────────────────────────────────────────────────

async function findFileByName(folderId: string, name: string) {
    const d = drive();
    const res = await d.files.list({
        q: `'${folderId}' in parents and name = '${name.replace(/'/g, "\\'")}' and trashed = false`,
        fields: 'files(id,name)',
        pageSize: 1,
    });
    return res.data.files?.[0];
}
function viewLink(fileId: string) {
    return `https://drive.google.com/file/d/${fileId}/view?usp=drive_link`;
}
async function createFile(
    folderId: string,
    name: string,
    mimeType: string,
    content: Buffer,
): Promise<{ id: string; link: string }> {
    const d = drive();
    const res = await d.files.create({
        requestBody: { name, parents: [folderId], mimeType },
        media: { mimeType, body: toStream(content) }, // Stream (multipart expects .pipe())
        fields: 'id',
    });
    return { id: res.data.id!, link: viewLink(res.data.id!) };
}
async function updateFile(
    fileId: string,
    mimeType: string,
    content: Buffer,
): Promise<{ id: string; link: string }> {
    const d = drive();
    const res = await d.files.update({
        fileId,
        media: { mimeType, body: toStream(content) }, // Stream (multipart expects .pipe())
        fields: 'id',
    });
    return { id: res.data.id!, link: viewLink(res.data.id!) };
}
async function upsertTextFile(
    folderId: string,
    name: string,
    csvText: string,
    mimeType = 'text/csv',
): Promise<{ id: string; link: string }> {
    const existing = await findFileByName(folderId, name);
    const buf = Buffer.from(csvText, 'utf8');
    if (!existing) return createFile(folderId, name, mimeType, buf);
    return updateFile(existing.id!, mimeType, buf);
}
async function upsertZipFromCsv(
    zipFolderId: string,
    zipName: string,
    innerCsvName: string,
    csvContent: string,
    password: string,
): Promise<{ id: string; link: string }> {
    const zipBuffer = await zipCsv(innerCsvName, csvContent, password);
    const existing = await findFileByName(zipFolderId, zipName);
    if (!existing) return createFile(zipFolderId, zipName, 'application/zip', zipBuffer);
    return updateFile(existing.id!, 'application/zip', zipBuffer);
}

// ───────────────────────────────────────────────────────────────────────────────
// main rebuild
// ───────────────────────────────────────────────────────────────────────────────

export async function rebuildQuarter(quarterId: string, opts?: { upload?: boolean }) {
    const upload = opts?.upload ?? true;
    if (!ZIP_PASSWORD || !ANON_SALT) throw new Error('Missing export.* config');
    if (upload && (!RAW_FOLDER_ID || !ZIP_FOLDER_ID)) {
        throw new Error('Missing drive.raw_folder_id / drive.zip_folder_id');
    }

    const qs = await db
        .collectionGroup('surveys')
        .where('quarterId', '==', quarterId)
        .where('status', '==', 'submitted')
        .get();

    const tmpl = (qs.docs[0]?.get('templateVersion') as string) ?? 'v1';
    const header = await ensureQuarterHeader(quarterId, tmpl);

    // KEY file header now carries clinic info
    const keyHeader = [
        'anonId',
        'uid',
        'email',
        'quarterId',
        'clinicId',
        'clinicName',
        'clinicProvince',
        'clinicCity',
    ];

    let dataContent = header.join(',') + '\n';
    let keyContent = keyHeader.join(',') + '\n';

    for (const d of qs.docs) {
        const uid = d.ref.parent?.parent?.id || '';
        const email = (await admin.auth().getUser(uid).catch(() => null))?.email ?? '';
        const answers = d.get('answers') ?? {};
        const version = (d.get('templateVersion') as string) ?? tmpl;
        const submittedAt = d.get('submittedAt')?.toDate?.() ?? null;

        const { dataRow, mappingRow } = await buildRowsForDoc(
            uid,
            email,
            quarterId,
            version,
            submittedAt,
            answers,
        );

        const row = header
            .map((h) => dataRow[h] ?? '')
            .map((v) => (typeof v === 'boolean' ? (v ? 'true' : 'false') : v));

        dataContent += csvLine(row as any[]);
        keyContent += csvLine([
            mappingRow.anonId,
            mappingRow.uid,
            mappingRow.email,
            mappingRow.quarterId,
            mappingRow.clinicId,
            mappingRow.clinicName,
            mappingRow.clinicProvince,
            mappingRow.clinicCity,
        ]);

        if (!d.get('exportedAt')) {
            await d.ref.set({ exportedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
        }
    }

    const { dataCsv, keyCsv, dataZip, keyZip } = namesForQuarter(quarterId);

    if (!upload) {
        const fs = await import('node:fs/promises');
        const path = await import('node:path');
        const outDir = path.join(process.cwd(), 'out');
        await fs.mkdir(outDir, { recursive: true });
        await fs.writeFile(path.join(outDir, dataCsv), dataContent, 'utf8');
        await fs.writeFile(path.join(outDir, keyCsv), keyContent, 'utf8');
        console.log(`Wrote local ./out/${dataCsv} and ./out/${keyCsv}`);
        return;
    }

    // Upload to PERSONAL DRIVE folders
    const dataMeta = await upsertTextFile(RAW_FOLDER_ID, dataCsv, dataContent, 'text/csv');
    const keyMeta = await upsertTextFile(RAW_FOLDER_ID, keyCsv, keyContent, 'text/csv');
    const dataZipMeta = await upsertZipFromCsv(ZIP_FOLDER_ID, dataZip, dataCsv, dataContent, ZIP_PASSWORD);
    const keyZipMeta = await upsertZipFromCsv(ZIP_FOLDER_ID, keyZip, keyCsv, keyContent, ZIP_PASSWORD);

    await db
        .collection('exports')
        .doc(quarterId)
        .set(
            {
                files: {
                    dataCsv: { id: dataMeta.id, link: dataMeta.link, name: dataCsv },
                    keyCsv: { id: keyMeta.id, link: keyMeta.link, name: keyCsv },
                    dataZip: { id: dataZipMeta.id, link: dataZipMeta.link, name: dataZip },
                    keyZip: { id: keyZipMeta.id, link: keyZipMeta.link, name: keyZip },
                },
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
        );

    console.log(`Rebuilt ${quarterId}: rows=${qs.size}`);
    console.log(`Drive links:\n- ${dataMeta.link}\n- ${keyMeta.link}\n- ${dataZipMeta.link}\n- ${keyZipMeta.link}`);
}

// ───────────────────────────────────────────────────────────────────────────────
// submit trigger
// ───────────────────────────────────────────────────────────────────────────────

export const onSurveySubmittedExport = onDocumentWritten(
    {
        region: 'northamerica-northeast1',
        document: 'users/{uid}/surveys/{quarterId}',
        secrets: EXPORT_SECRETS,
    },
    async (event) => {
        const { quarterId } = event.params as { uid: string; quarterId: string };
        const change = event.data;
        if (!change) return;

        const after = change.after.exists ? (change.after.data() as any) : null;
        const before = change.before.exists ? (change.before.data() as any) : null;
        if (!after) return;

        const status = (after.status as string | undefined)?.toLowerCase();
        const prev = (before?.status as string | undefined)?.toLowerCase();
        const already = !!after.exportedAt;

        if (status !== 'submitted') return;
        if (prev === 'submitted' && already) return;

        await rebuildQuarter(quarterId, { upload: true });
        await change.after.ref.set(
            { exportedAt: admin.firestore.FieldValue.serverTimestamp() },
            { merge: true },
        );
    },
);

// ───────────────────────────────────────────────────────────────────────────────
// nightly safety net
// ───────────────────────────────────────────────────────────────────────────────

export const nightlyExportRebuild = onSchedule(
    {
        region: 'northamerica-northeast1',
        schedule: '0 3 * * *',
        timeZone: "America/Regina",
        secrets: EXPORT_SECRETS,
    },
    async () => {
        const insts = await db.collection('survey_instances').orderBy('opensAt', 'desc').limit(3).get();

        const quarters = Array.from(
            new Set(insts.docs.map((d) => (d.get('quarter') as string) ?? d.id)),
        ).slice(0, 2);

        for (const q of quarters) await rebuildQuarter(q, { upload: true });
    },
);

// ───────────────────────────────────────────────────────────────────────────────
// local CLI
// ───────────────────────────────────────────────────────────────────────────────

if (require.main === module) {
    (async () => {
        const argv = process.argv.slice(2);
        const qi = argv.indexOf('--quarter');
        const quarter = qi >= 0 ? argv[qi + 1] : undefined;
        //const rebuild = argv.includes('--rebuild');
        const upload = argv.includes('--upload');

        if (!quarter) {
            console.error('Usage: ts-node src/export_quarter.ts --quarter "2025-Q2" [--upload]');
            process.exit(1);
        }

        await rebuildQuarter(quarter, { upload });
        process.exit(0);
    })().catch((e) => {
        console.error(e);
        process.exit(1);
    });
}
