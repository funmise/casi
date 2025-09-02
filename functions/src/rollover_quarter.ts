import * as admin from "firebase-admin";
import { rolloverQuarterSurvey } from "./index";

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
(async () => {
    try {
        const result = await rolloverQuarterSurvey({ templateVersion: "v1" });
        console.log("Rollover result:", result);
        process.exit(0);
    } catch (err) {
        console.error("Error running rollover:", err);
        process.exit(1);
    }
})();
