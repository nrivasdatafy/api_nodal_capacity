import { SimpleObject } from '../typings/globals';
import {
  DEFAULT_SCHEMA,
  secureQueryPerformer,
  setDefaulSchema,
  simpleQueryPerformer
} from '../lib/sqlutils';

export default class BaseService {
  readonly schema: string;

  /**
   * Constructor for the BaseService class.
   * Sets the default schema for all queries executed by this instance.
   *
   * @param schema - The schema name to be used for queries. Defaults to `DEFAULT_SCHEMA`.
   */
  constructor(schema: string = DEFAULT_SCHEMA) {
    this.schema = schema;
    setDefaulSchema(schema);
  }

  /**
   * Executes a simple SQL query.
   *
   * @param queryString - SQL query as a string.
   * @param camelizeColumns - If `true`, transforms column names from snake_case to camelCase. Default is `true`.
   * @param inhibitLog - If `true`, suppresses logging to the console. Default is `false`.
   * @param schemaName - The schema to use for the query. Defaults to the schema set in the instance.
   * @returns A promise resolving to an array of objects representing the query results.
   */
  public async baseSimpleQueryPerformer({
    queryString,
    camelizeColumns = true,
    inhibitLog = false,
    schemaName = this.schema
  }: {
    queryString: string;
    camelizeColumns?: boolean;
    inhibitLog?: boolean;
    schemaName?: string;
  }): Promise<Array<SimpleObject>> {
    return await simpleQueryPerformer({
      queryString,
      camelizeColumns,
      inhibitLog,
      schemaName
    });
  }

  /**
   * Executes a secure SQL query with parameters.
   * Protects against SQL injection by separating the query and its values.
   *
   * @param queryString - SQL query as a string with placeholders for parameters (`$1`, `$2`, etc.).
   * @param queryParams - Array of values to insert into the placeholders in the query.
   * @param camelizeColumns - If `true`, transforms column names from snake_case to camelCase. Default is `true`.
   * @param inhibitLog - If `true`, suppresses logging to the console. Default is `false`.
   * @param schemaName - The schema to use for the query. Defaults to the schema set in the instance.
   * @returns A promise resolving to an array of objects representing the query results.
   *
   * ### Supported Parameter Formats:
   * 1. **Single Value**
   *    - Query: `"SELECT * FROM users WHERE id = $1"`
   *    - Params: `[42]`
   *
   * 2. **Multiple Values in WHERE Clause**
   *    - Query: `"SELECT * FROM users WHERE id IN ($1, $2, $3)"`
   *    - Params: `[1, 2, 3]`
   *
   * 3. **Using Arrays in PostgreSQL (Preferred for IN clauses)**
   *    - Query: `"SELECT * FROM users WHERE id = ANY($1)"`
   *    - Params: `[[1, 2, 3]]` (Passing an array as a single parameter)
   *
   * 4. **Named Placeholders (not supported natively in `pg`, but useful for ORMs)**
   *    - Query: `"SELECT * FROM users WHERE email = $1 AND status = $2"`
   *    - Params: `["user@example.com", "active"]`
   *
   * 5. **Date and Timestamp**
   *    - Query: `"SELECT * FROM orders WHERE created_at >= $1"`
   *    - Params: `[new Date("2024-01-01T00:00:00Z")]`
   *
   * 6. **Boolean Values**
   *    - Query: `"SELECT * FROM users WHERE is_active = $1"`
   *    - Params: `[true]`
   *
   * 7. **JSON/JSONB Columns in PostgreSQL**
   *    - Query: `"INSERT INTO config (settings) VALUES ($1)"`
   *    - Params: `[JSON.stringify({ theme: "dark", notifications: true })]`
   *
   * 8. **Full-Text Search**
   *    - Query: `"SELECT * FROM articles WHERE to_tsvector(content) @@ plainto_tsquery($1)"`
   *    - Params: `["javascript"]`
   *
   * 9. **Schema Selection (Dynamic Schema Usage)**
   *    - Query: `"SET SCHEMA '${schemaName}'"` (Automatically set inside `secureQueryPerformer`)
   *
   * **🚨 Avoid String Concatenation**
   * Never use string interpolation (e.g., `WHERE name = '${userInput}'`) as it exposes your query to SQL injection risks.
   */
  public async baseSecureQueryPerformer({
    queryString,
    queryParams,
    camelizeColumns = true,
    inhibitLog = false,
    schemaName = this.schema
  }: {
    queryString: string;
    queryParams: any[];
    camelizeColumns?: boolean;
    inhibitLog?: boolean;
    schemaName?: string;
  }): Promise<Array<SimpleObject>> {
    return await secureQueryPerformer({
      queryString,
      queryParams,
      camelizeColumns,
      inhibitLog,
      schemaName
    });
  }
}
