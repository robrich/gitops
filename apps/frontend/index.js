#!/usr/bin/env node

import app from './app.js';
import debug from 'debug';
import http from 'http';
import { readFile } from 'fs/promises';

debug('frontend:server');

const port = process.env.PORT || '3000';
app.set('port', port);

const server = http.createServer(app);

const version = JSON.parse(await readFile('./version.json', 'utf8'));
app.set('hash', version?.hash);
app.set('branch', version?.branch);

server.on('error', function onError(error) {
  console.error(err);
  process.exit(1);
});
server.listen(port, function onListening() {
  console.log(`Listening on http://+:${port}/, hash: ${app.get('hash')}, branch: ${app.get('branch')}`);
});
