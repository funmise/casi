/* eslint-disable no-console */

/**
 * Local runner for rebuilding and (optionally) uploading a quarter's exports.
 *
 * Usage:
 *   ts-node src/local/export_quarter_runner.ts --quarter 2025-Q2 --rebuild [--upload]
 *
 * What this does:
 *   1) Loads .runtimeconfig.json if present and maps keys → process.env
 *   2) Initializes Firebase Admin SDK using ./serviceAccountKey.json
 *   3) Requires ../export_quarter (CommonJS require to play nicely with ts-node)
 *   4) Calls rebuildQuarter(quarter, { upload })
 */

import * as path from 'node:path';
import * as fs from 'node:fs';
import * as admin from 'firebase-admin';

// ───────────────────────────────────────────────────────────────────────────────
// 1) Load .runtimeconfig.json (optional) and map to env vars expected by exporter
// ───────────────────────────────────────────────────────────────────────────────
function tryLoadRuntimeConfig() {
    const cfgPath = path.resolve(__dirname, '../../.runtimeconfig.json');
    if (!fs.existsSync(cfgPath)) return;

    try {
        const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
        const drv = cfg.drive || {};
        const exp = cfg.export || {};

        // OAuth client + token
        process.env.DRIVE_CLIENT_ID ||= drv.client_id || exp.drive_client_id;
        process.env.DRIVE_CLIENT_SECRET ||= drv.client_secret || exp.drive_client_secret;
        process.env.DRIVE_REFRESH_TOKEN ||= drv.refresh_token || exp.drive_refresh_token;

        // Folder IDs
        process.env.DRIVE_RAW_FOLDER_ID ||= drv.raw_folder_id || exp.drive_raw_folder_id;
        process.env.DRIVE_ZIP_FOLDER_ID ||= drv.zip_folder_id || exp.drive_zip_folder_id;

        // Export settings
        process.env.EXPORT_CSV_PASSWORD ||= exp.csv_password;
        process.env.EXPORT_SALT ||= exp.salt;

        console.log('Loaded env from .runtimeconfig.json');
    } catch (e) {
        console.warn('Warning: failed to parse .runtimeconfig.json:', e);
    }
}

// ───────────────────────────────────────────────────────────────────────────────
// 2) Initialize Firebase Admin with serviceAccountKey.json (before Firestore use)
// ───────────────────────────────────────────────────────────────────────────────
function initAdmin() {
    const saPath = path.resolve(__dirname, '../../serviceAccountKey.json');
    if (!fs.existsSync(saPath)) {
        throw new Error(`Missing serviceAccountKey.json at ${saPath}`);
    }
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const serviceAccount = require(saPath);
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id,
        });
    }
    console.log(`Firebase Admin initialized for project ${serviceAccount.project_id}`);
}

// ───────────────────────────────────────────────────────────────────────────────
// 3) CLI args
// ───────────────────────────────────────────────────────────────────────────────
function parseArgs() {
    const args = process.argv.slice(2);
    const qIdx = args.indexOf('--quarter');
    const quarter = (qIdx >= 0 ? args[qIdx + 1] : undefined) ?? args[0];
    const upload = args.includes('--upload');
    return { quarter, upload };
}

// ───────────────────────────────────────────────────────────────────────────────
// 4) Main
// ───────────────────────────────────────────────────────────────────────────────
(async () => {
    try {
        tryLoadRuntimeConfig();
        initAdmin();

        const { quarter, upload, } = parseArgs();
        if (!quarter) {
            console.error('Usage: ts-node src/local/export_quarter_runner.ts --quarter 2025-Q2 [--upload]');
            process.exit(1);
        }

        const { rebuildQuarter } = require('../export_quarter');

        await rebuildQuarter(quarter, { upload });
        console.log('Done.');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
})();
