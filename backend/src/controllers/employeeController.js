const db = require('../database/db');

/**
 * GET /api/employees
 * Fetches all employees.
 */
async function getAllEmployees(req, res, next) {
  try {
    const result = await db.query(
      'SELECT id, name, email, department, position, phone, created_at, updated_at FROM employees ORDER BY id ASC'
    );
    res.status(200).json({
      data: result.rows,
      count: result.rowCount
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/employees/:id
 * Fetches a single employee by ID.
 */
async function getEmployeeById(req, res, next) {
  try {
    const { id } = req.params;
    const result = await db.query(
      'SELECT id, name, email, department, position, phone, created_at, updated_at FROM employees WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Employee with ID ${id} was not found.`
      });
    }

    res.status(200).json({
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/employees
 * Creates a new employee.
 */
async function createEmployee(req, res, next) {
  try {
    const { name, email, department, position, phone } = req.body;
    const result = await db.query(
      `INSERT INTO employees (name, email, department, position, phone, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, name, email, department, position, phone, created_at, updated_at`,
      [name, email, department, position, phone]
    );

    res.status(201).json({
      message: 'Employee created successfully',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * PUT /api/employees/:id
 * Updates an existing employee.
 */
async function updateEmployee(req, res, next) {
  try {
    const { id } = req.params;
    const { name, email, department, position, phone } = req.body;

    const result = await db.query(
      `UPDATE employees
       SET name = $1, email = $2, department = $3, position = $4, phone = $5, updated_at = CURRENT_TIMESTAMP
       WHERE id = $6
       RETURNING id, name, email, department, position, phone, created_at, updated_at`,
      [name, email, department, position, phone, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Employee with ID ${id} was not found.`
      });
    }

    res.status(200).json({
      message: 'Employee updated successfully',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
}

/**
 * DELETE /api/employees/:id
 * Deletes an employee by ID.
 */
async function deleteEmployee(req, res, next) {
  try {
    const { id } = req.params;
    const result = await db.query(
      'DELETE FROM employees WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: `Employee with ID ${id} was not found.`
      });
    }

    res.status(200).json({
      message: `Employee with ID ${id} deleted successfully.`
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getAllEmployees,
  getEmployeeById,
  createEmployee,
  updateEmployee,
  deleteEmployee
};
