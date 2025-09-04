import * as admin from 'firebase-admin';
import path from 'path';
import { rolloverQuarterSurvey } from '../index';

// ---- Firebase Admin init 
const sa = require(path.resolve(__dirname, '../../serviceAccountKey.json'));

// Make the project id visible to Google libs when running locally
process.env.GCLOUD_PROJECT = sa.project_id;
process.env.GOOGLE_CLOUD_PROJECT = sa.project_id;

// Initialize Admin with explicit projectId
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(sa),
        projectId: sa.project_id,
    } as any);
}
// ---- tiny argv parser: --template v2  |  --templateVersion v2  |  -t v2  |  positional v2
function getTemplateVersion(): string {
    const argv = process.argv.slice(2);
    const flagIdx = argv.findIndex(
        a => a === '--template' || a === '--templateVersion' || a === '-t'
    );
    if (flagIdx >= 0 && argv[flagIdx + 1] && !argv[flagIdx + 1].startsWith('-')) {
        return argv[flagIdx + 1];
    }
    const positional = argv.find(a => !a.startsWith('-'));
    return positional ?? 'v1';
}

(async () => {
    const templateVersion = getTemplateVersion();
    console.log(`-- rollover:quarter --  templateVersion=${templateVersion}`);

    const result = await rolloverQuarterSurvey({ templateVersion });

    console.log(`Activated ${result.activated}; deactivated [${result.deactivated.join(', ')}]`);
    process.exit(0);
})().catch(err => {
    console.error(err);
    process.exit(1);
});
