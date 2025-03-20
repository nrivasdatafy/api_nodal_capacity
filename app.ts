import express, { NextFunction, Request, Response, Router } from 'express';
import expressListRoutes from 'express-list-routes';
import path from 'path';
import logger, { appErrorLogger, requestLogger } from './lib/logger';
import dotenv from 'dotenv';
import authRouter from './routes/api/auth';
import mapElementsRouter from './routes/api/mapElements';
import alimentadorRouter from './routes/api/alimentador';
import comunaRouter from './routes/api/comuna';
import regionRouter from './routes/api/region';
import nodalCapacityRouter from './routes/api/nodalCapacity';

dotenv.config();

// Initialize express into a variable
const app = express();
process.env.TZ = 'UTC';

// Use custom logger for all the incoming requests
app.use(requestLogger);

// Express is going to parser the body instead of bodyparser
app.use(
  express.json({
    limit: '60mb',
    verify: (req: Request, _: Response, buf: Buffer, __: string) => (req.rawBody = buf.toString())
  })
);

app.use(express.urlencoded({ extended: true, limit: '60mb' }));

const API_BASE_URL = '/api';

const routes: { url: string; router: Router }[] = [
  { url: `${API_BASE_URL}/auth`, router: authRouter },
  { url: `${API_BASE_URL}/mapElements`, router: mapElementsRouter },
  { url: `${API_BASE_URL}/alimentador`, router: alimentadorRouter },
  { url: `${API_BASE_URL}/comuna`, router: comunaRouter },
  { url: `${API_BASE_URL}/region`, router: regionRouter },
  { url: `${API_BASE_URL}/nodalCapacity`, router: nodalCapacityRouter }
];

// Register all available routes
routes.forEach(({ url, router }) => {
  app.use(url, router);
  expressListRoutes(router, { prefix: url });
});

// On production and development we serve the compiled version of the web app
if (process.env.NODE_ENV === 'production' || process.env.NODE_ENV === 'development') {
  app.use(express.static('../build'));
  app.get('/*', (_, res) => res.sendFile(path.resolve(path.resolve('../'), 'build', 'index.html')));
}

// Generic error handling
app.use((err: Error, req: Request, res: Response, _: NextFunction) => {
  logger.error(`API error: ${err} - ${req.rawBody}`);

  const addMessageIf = (prefix: string, value: any) => {
    if (value) {
      message.push(prefix + value);
    }
  };

  const message = [
    `URL - ${req.url} was unable to process the request`,
    `Details - ${err.message}`
  ];

  addMessageIf('Body - ', req.rawBody);
  addMessageIf('User - ', req.user?._id);

  res.status(500).send('Internal API error');
});

app.use(appErrorLogger);

export default app;
