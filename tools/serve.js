const http = require('http');
const fs = require('fs');
const path = require('path');

const mime = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.wasm': 'application/wasm',
    '.pck': 'application/octet-stream',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.json': 'application/json',
    '.mp3': 'audio/mpeg',
    '.ogg': 'audio/ogg',
    '.wav': 'audio/wav',
    '.css': 'text/css; charset=utf-8',
    '.ttf': 'font/ttf',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2'
};

const args = process.argv.slice(2);
let port = 5173;
let dir = 'build/web';

for (let i = 0; i < args.length; i++) {
    if (args[i] === '--port' && args[i + 1]) port = parseInt(args[++i], 10);
    else if (args[i] === '--dir' && args[i + 1]) dir = args[++i];
}

const targetDir = path.resolve(dir);

const server = http.createServer((req, res) => {
    let rel = req.url === '/' ? '/index.html' : req.url.split('?')[0];
    let filePath = path.join(targetDir, rel);

    // Basic path traversal prevention
    if (!filePath.startsWith(targetDir)) {
        res.writeHead(403);
        return res.end();
    }

    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        return res.end('404 Not Found');
    }

    const stat = fs.statSync(filePath);
    const ext = path.extname(filePath).toLowerCase();

    res.writeHead(200, {
        'Content-Type': mime[ext] || 'application/octet-stream',
        'Content-Length': stat.size,
        'Access-Control-Allow-Origin': '*',
        'Cross-Origin-Resource-Policy': 'cross-origin',
        'Cache-Control': 'no-cache'
    });

    const stream = fs.createReadStream(filePath);
    stream.pipe(res);
    stream.on('error', () => {
        try { res.end(); } catch (e) {}
    });
});

server.listen(port, '0.0.0.0', () => {
    console.log(`Serving ${targetDir} at http://localhost:${port} ...`);
});

process.on('SIGINT', () => {
    console.log('\nServer stopped.');
    process.exit(0);
});
