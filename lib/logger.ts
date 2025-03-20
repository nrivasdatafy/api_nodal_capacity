import expressWinston from 'express-winston';
import winston from 'winston';

const { combine, prettyPrint } = winston.format;

const appLogger = winston.createLogger({
  transports: [new winston.transports.Console()],
  format: winston.format.combine(
    winston.format.errors({ stack: true }),
    winston.format.printf((info) => `${info.level}: ${info.stack || JSON.stringify(info.message)}`)
  )
});

export const requestLogger = expressWinston.logger({
  format: combine(
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    winston.format.printf((info) => `${info.timestamp} ${info.message}`)
  ),
  expressFormat: false,
  transports: [new winston.transports.Console()],
  meta: false,
  msg: `{{req.method}} {{req.originalUrl}} {{res.statusCode}} {{req.connection.remoteAddress}} {{req.headers["user-agent"]}}`
});

export const appErrorLogger = expressWinston.errorLogger({
  transports: [new winston.transports.Console()],
  format: combine(
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    prettyPrint()
  )
});

export default appLogger;
