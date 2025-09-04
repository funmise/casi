import { google } from 'googleapis';
import * as http from 'node:http';
import * as url from 'node:url';

const CLIENT_ID = process.env.DRIVE_CLIENT_ID!;
const CLIENT_SECRET = process.env.DRIVE_CLIENT_SECRET!;
const REDIRECT_URI = 'http://localhost:3582/callback';

async function main() {
    const oauth2 = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);

    const authUrl = oauth2.generateAuthUrl({
        access_type: 'offline',
        prompt: 'consent',
        scope: ['https://www.googleapis.com/auth/drive.file'],
    });

    console.log('\nOpen this URL in your browser:\n', authUrl, '\n');

    const code: string = await new Promise((resolve) => {
        const server = http.createServer((req, res) => {
            const q = url.parse(req.url || '', true).query;
            const c = (q.code as string) || '';
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end('<h2>OK - you can close this tab.</h2>');
            server.close(() => resolve(c));
        });
        server.listen(3582, '127.0.0.1', () => { });
    });

    if (!code) {
        console.error('No code found. Try again.');
        process.exit(1);
    }

    const { tokens } = await oauth2.getToken(code);
    console.log('\nAccess token:', tokens.access_token);
    console.log('Refresh token:', tokens.refresh_token);
    console.log('Save the refresh token somewhere safe.\n');
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});

// Usage: npx ts-node src/local/drive_token.ts