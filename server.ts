import config from 'config';
//import { readFileSync } from 'fs';
// import { createServer } from 'https';
import { createServer } from 'http';
import app from './app';
import logger from './lib/logger';
import { BackendConfig } from './typings/globals';

const port=3000;

const server = createServer(
  // {
  //   key: readFileSync("./cert/key.pem"),
  //   cert: readFileSync("./cert/cert.pem"),
  // },
  app
);

server.listen(port, () => {
  logger.info(`Secure server running on port ${port}`);
});
