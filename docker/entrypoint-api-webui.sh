#!/bin/sh
set -e

if [ -d "/app/webui" ]; then
  cat >/tmp/webui-server.mjs <<'SERVER'
import { createServer } from 'http';
import { createReadStream, promises as fs } from 'fs';
import { join, normalize } from 'path';
import mime from 'mime';

const root = process.env.WEBUI_DIR || '/app/webui';
const port = Number(process.env.WEBUI_PORT) || 4173;
const indexPath = join(root, 'index.html');

const server = createServer(async (req, res) => {
  const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
  const normalizedPath = normalize(urlPath).replace(/^[/\\]/, '');
  const safePath = normalizedPath.startsWith('..') ? '' : normalizedPath;
  const targetPath = join(root, safePath);

  try {
    const stats = await fs.stat(targetPath);
    if (stats.isFile()) {
      res.writeHead(200, { 'Content-Type': mime.getType(targetPath) || 'application/octet-stream' });
      createReadStream(targetPath).pipe(res);
      return;
    }
  } catch (err) {
    // fall back to index.html
  }

  try {
    const content = await fs.readFile(indexPath);
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(content);
  } catch (err) {
    res.writeHead(500);
    res.end('index.html not found');
  }
});

server.listen(port, () => {
  console.log(`Web UI available at port ${port}`);
});
SERVER

  WEBUI_DIR="/app/webui" WEBUI_PORT="${WEBUI_PORT:-4173}" node /tmp/webui-server.mjs &
fi

exec yarn start
