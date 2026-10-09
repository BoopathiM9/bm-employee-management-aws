/**
 * Validates request body for employee creation and updates.
 */
function validateEmployee(req, res, next) {
  const { name, email, department, position, phone } = req.body;
  const errors = [];

  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    errors.push('Field "name" is required and must be a non-empty string.');
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || typeof email !== 'string' || !emailRegex.test(email.trim())) {
    errors.push('Field "email" is required and must be a valid email address.');
  }

  if (!department || typeof department !== 'string' || department.trim().length === 0) {
    errors.push('Field "department" is required and must be a non-empty string.');
  }

  if (!position || typeof position !== 'string' || position.trim().length === 0) {
    errors.push('Field "position" is required and must be a non-empty string.');
  }

  if (phone && typeof phone !== 'string') {
    errors.push('Field "phone" must be a string.');
  }

  if (errors.length > 0) {
    return res.status(400).json({
      error: 'Validation Error',
      details: errors
    });
  }

  // Clean values
  req.body.name = name.trim();
  req.body.email = email.trim().toLowerCase();
  req.body.department = department.trim();
  req.body.position = position.trim();
  req.body.phone = phone ? phone.trim() : null;

  next();
}

/**
 * Validates integer ID parameter.
 */
function validateId(req, res, next) {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id) || id <= 0) {
    return res.status(400).json({
      error: 'Validation Error',
      details: ['Employee ID must be a positive integer.']
    });
  }
  req.params.id = id;
  next();
}

module.exports = {
  validateEmployee,
  validateId
};
