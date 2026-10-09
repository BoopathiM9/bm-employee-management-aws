require('dotenv').config();
const app = require('./app');
const db = require('./database/db');

const PORT = parseInt(process.env.PORT, 10) || 8080;

// Initialize server
const server = app.listen(PORT, async () => {
  console.log(`=========================================`);
  console.log(`BM Employee Management Backend API`);
  console.log(`Server listening on port : ${PORT}`);
  console.log(`Environment              : ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health Check             : http://localhost:${PORT}/health`);
  console.log(`Employees API            : http://localhost:${PORT}/api/employees`);
  console.log(`=========================================`);

  try {
    // Attempt database initialization
    await db.initDatabase();
  } catch (err) {
    console.warn('[Warning] Could not initialize database immediately:', err.message);
    console.warn('[Warning] Database connection will retry upon first client request.');
  }
});

// Graceful shutdown handling
async function handleShutdown(signal) {
  console.log(`\n[Shutdown] Received ${signal}. Closing HTTP server and database pool...`);
  server.close(async () => {
    console.log('[Shutdown] HTTP server closed.');
    try {
      await db.closePool();
      console.log('[Shutdown] Database pool closed cleanly.');
      process.exit(0);
    } catch (err) {
      console.error('[Shutdown Error] Failed to close database pool:', err.message);
      process.exit(1);
    }
  });

  // Force exit if hanging
  setTimeout(() => {
    console.error('[Shutdown] Forcefully exiting after timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('SIGINT', () => handleShutdown('SIGINT'));
