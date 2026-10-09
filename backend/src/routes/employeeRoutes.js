const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');
const { validateEmployee, validateId } = require('../middleware/validator');

// GET all employees
router.get('/', employeeController.getAllEmployees);

// GET employee by ID
router.get('/:id', validateId, employeeController.getEmployeeById);

// POST create employee
router.post('/', validateEmployee, employeeController.createEmployee);

// PUT update employee
router.put('/:id', validateId, validateEmployee, employeeController.updateEmployee);

// DELETE employee
router.delete('/:id', validateId, employeeController.deleteEmployee);

module.exports = router;
