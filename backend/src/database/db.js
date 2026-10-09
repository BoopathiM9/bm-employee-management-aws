const { Pool } = require('pg');
const { getDatabaseCredentials } = require('../services/secretsManager');

let pool = null;

/**
 * Initializes and returns the PostgreSQL connection pool.
 */
async function getPool() {
  if (pool) {
    return pool;
  }

  const credentials = await getDatabaseCredentials();

  const isProduction = process.env.NODE_ENV === 'production' || process.env.USE_SECRETS_MANAGER === 'true';

  pool = new Pool({
    host: credentials.host,
    port: credentials.port,
    database: credentials.database,
    user: credentials.user,
    password: credentials.password,
    max: 20, // Connection pool maximum size
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    ssl: isProduction ? { rejectUnauthorized: false } : false
  });

  pool.on('error', (err) => {
    console.error('[PostgreSQL Pool Error] Unexpected error on idle client:', err);
  });

  return pool;
}

/**
 * Executes a parameterized SQL query safely.
 * Never concatenate raw user input into SQL queries.
 */
async function query(text, params) {
  const activePool = await getPool();
  const start = Date.now();
  try {
    const res = await activePool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV !== 'production') {
      console.log(`[SQL Query] Executed query in ${duration}ms | rows: ${res.rowCount}`);
    }
    return res;
  } catch (error) {
    console.error('[SQL Error] Query failed:', { text, error: error.message });
    throw error;
  }
}

/**
 * Verifies connection and ensures the employees table exists.
 */
async function initDatabase() {
  const schemaSql = `
    CREATE TABLE IF NOT EXISTS employees (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      email VARCHAR(150) UNIQUE NOT NULL,
      department VARCHAR(100) NOT NULL,
      position VARCHAR(100) NOT NULL,
      phone VARCHAR(30),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `;
  await query(schemaSql);
  console.log('[Database] Schema checked / employees table verified.');
}

/**
 * Gracefully shuts down the connection pool.
 */
async function closePool() {
  if (pool) {
    console.log('[Database] Closing PostgreSQL connection pool...');
    await pool.end();
    pool = null;
  }
}

module.exports = {
  getPool,
  query,
  initDatabase,
  closePool
};
