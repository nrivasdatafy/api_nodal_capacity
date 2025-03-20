import FS from 'fs';
import path from 'path';
import { Pool, types } from 'pg';
import { isLocalhost, isProduction } from './env';
import { snakeToCamelTransformer } from './parser';
import dotenv from 'dotenv';

dotenv.config();

const PG_USER = process.env.PG_USER;
const PG_PASSWORD = process.env.PG_PASSWORD;
const PG_HOST = process.env.PG_HOST;
const PG_DATABASE = process.env.PG_DATABASE;
const PG_SCHEMA = process.env.PG_SCHEMA;
const PG_PORT = !isNaN(Number(process.env.PG_PORT)) ? Number(process.env.PG_PORT) : 5432;
export const DEFAULT_SCHEMA = PG_SCHEMA;

// Identifiers of numeric data types in PostgreSQL
const INT4 = 23; // int4 (INTEGER)
const FLOAT8 = 701; // float8 (DOUBLE PRECISION)
const NUMERIC = 1700; // numeric

types.setTypeParser(INT4, (val) => (!isNaN(Number(val)) ? parseInt(val, 10) : val));
types.setTypeParser(FLOAT8, (val) => (!isNaN(Number(val)) ? parseFloat(val) : val));
types.setTypeParser(NUMERIC, (val) => (!isNaN(Number(val)) ? parseFloat(val) : val));

export const CERT_SUFFIX = isProduction() ? 'prod' : 'dev';
const CERT_DIR = path.resolve('db_cert');

export const pool = new Pool({
  user: PG_USER,
  host: PG_HOST,
  database: PG_DATABASE,
  password: PG_PASSWORD,
  port: PG_PORT,
  ...(isLocalhost()
    ? {}
    : {
        // NOTE: In case of using SSL certificates, uncomment this and add the certificates in the directory ./db_cert/ with the corresponding names and suffixes (dev/prod).
        // ssl: {
        //   rejectUnauthorized: false,
        //   ca: FS.readFileSync(`${CERT_DIR}/server-ca-${CERT_SUFFIX}.pem`).toString(),
        //   key: FS.readFileSync(`${CERT_DIR}/client-key-${CERT_SUFFIX}.pem`).toString(),
        //   cert: FS.readFileSync(`${CERT_DIR}/client-cert-${CERT_SUFFIX}.pem`).toString()
        // }
      })
});

const camelizeQueryResult = (result: { rows: Array<any> }) => {
  if (result && result.rows && Array.isArray(result.rows) && result.rows.length > 0) {
    for (const row of result.rows) {
      snakeToCamelTransformer(row);
    }
  }
};

export const setDefaulSchema = async (schemaName: string) => {
  let client: any;
  try {
    client = await pool.connect();
    await client.query(`SET SCHEMA '${schemaName}'`);
    client.release();
  } catch (error) {
    console.error(error);
    if (client) {
      client.release();
    }
    throw error;
  }
};

export const simpleQueryPerformer = async ({
  schemaName = DEFAULT_SCHEMA,
  queryString,
  camelizeColumns = false,
  inhibitLog = false
}: {
  schemaName?: string;
  queryString: string;
  camelizeColumns?: boolean;
  inhibitLog?: boolean;
}): Promise<Array<{ [key: string]: string }>> => {
  let client: any;

  try {
    client = await pool.connect();
    if (!inhibitLog) {
      console.log(`[DB: ${PG_DATABASE}] Running query on schema: '${schemaName}'`);
      console.log(`Running query: ${queryString}`);
    }

    await client.query(`SET SCHEMA '${schemaName}'`);
    const result = await client.query(queryString);
    client.release();

    if (camelizeColumns) {
      camelizeQueryResult(result);
    }

    return result.rows;
  } catch (error) {
    console.error('Error in simpleQueryPerformer: ', error);
    if (client) {
      client.release();
    }
    throw error;
  }
};

export const secureQueryPerformer = async ({
  schemaName = DEFAULT_SCHEMA,
  queryString,
  queryParams = [],
  camelizeColumns = false,
  inhibitLog = false
}: {
  schemaName?: string;
  queryString: string;
  queryParams?: Array<any>;
  camelizeColumns?: boolean;
  inhibitLog?: boolean;
}): Promise<Array<{ [key: string]: any }>> => {
  let client: any;

  try {
    client = await pool.connect();

    if (!inhibitLog) {
      console.log(`[DB: ${PG_DATABASE}] Running query on schema: '${schemaName}'`);
      console.log(`Running query: ${queryString}`);
      console.log(`With params: ${JSON.stringify(queryParams)}`);
    }

    // Establecer el esquema
    await client.query(`SET SCHEMA '${schemaName}'`);

    // Ejecutar la consulta con parámetros
    const result = await client.query(queryString, queryParams);
    client.release();

    // Transformar columnas a camelCase si está habilitado
    if (camelizeColumns) {
      camelizeQueryResult(result);
    }

    return result.rows;
  } catch (error) {
    console.error('Error in secureQueryPerformer: ', error);
    if (client) {
      client.release();
    }
    throw error;
  }
};
