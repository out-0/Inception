const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const PUBLIC_DIR = path.join(__dirname, 'app');

// Mapping of file extensions to file types to use in Content-Type header
const MIME_TYPES = {
	'.html': 'text/html; charset=UTF-8',
	'.css': 'text/css; charset=UTF-8',
	'.js': 'application/javascript; charset=UTF-8',
	'.json': 'application/json; charset=UTF-8',
	'.png': 'image/png',
	'.jpg': 'image/jpeg',
	'.ico': 'image/x-icon',
	'.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
	let cleanUrl = req.url.split('?')[0];
	if (cleanUrl === '/' || cleanUrl === '') {
		cleanUrl = '/index.html';
	}

	//Security guard again request ../../etc/passwd trying to escape app folder
	const safePath = path.normalize(cleanUrl).replace(/^(\.\.[\/\\])+/, '');
	const filePath = path.join(PUBLIC_DIR, safePath);

	fs.stat(filePath, (err, stats) => {
		if (err || !stats.isFile()) {
			res.writeHead(404, { 'Content-Type': 'text/plain' });
			res.end('404 Not Found');
			return;
		}

		const ext = path.extname(filePath).toLowerCase();
		const contentType = MIME_TYPES[ext] || 'application/octet-stream';

		fs.readFile(filePath, (readErr, data) => {
			if (readErr) {
				res.writeHead(500, { 'Content-Type': 'text/plain' });
				res.end('500 Server Error');
				return;
			}
			res.writeHead(200, { 'Content-Type': contentType });
			res.end(data);
		});
	});

	server.listen(PORT, '0.0.0.0', () => {
		console.log(`Static site server listening on port ${PORT}...`);
	})
});
