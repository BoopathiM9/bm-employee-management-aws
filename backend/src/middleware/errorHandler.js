/**
 * Centralized error-handling middleware.
 */
function errorHandler(err, req, res, next) {
  console.error('[Error Handler] Caught error:', {
    message: err.message,
    code: err.code,
    stack: process.env.NODE_ENV === 'production' ? undefined : err.stack
  });

  // Unique constraint violation (e.g. duplicate email in Postgres)
  if (err.code === '23505') {
    return res.status(409).json({
      error: 'Conflict',
      message: 'An employee with this email already exists.'
    });
  }

  // Postgres foreign key or invalid syntax
  if (err.code === '22P02') {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Invalid data format provided.'
    });
  }

  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    error: statusCode === 500 ? 'Internal Server Error' : err.name || 'Error',
    message: err.message || 'An unexpected error occurred.'
  });
}

module.exports = errorHandler;
