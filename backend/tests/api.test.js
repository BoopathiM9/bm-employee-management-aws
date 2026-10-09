const request = require('supertest');

// Mock the database module before importing the app
jest.mock('../src/database/db', () => ({
  query: jest.fn(),
  initDatabase: jest.fn().mockResolvedValue(),
  closePool: jest.fn().mockResolvedValue()
}));

const db = require('../src/database/db');
const app = require('../src/app');

describe('Employee Management API Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /health', () => {
    it('should return 200 and healthy status', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('healthy');
      expect(res.body.service).toBe('bm-employee-backend');
    });
  });

  describe('GET /api/employees', () => {
    it('should return 200 and a list of employees', async () => {
      const mockEmployees = [
        { id: 1, name: 'Alice Smith', email: 'alice@example.com', department: 'Engineering', position: 'Cloud Engineer', phone: '1234567890' },
        { id: 2, name: 'Bob Jones', email: 'bob@example.com', department: 'Finance', position: 'Analyst', phone: '9876543210' }
      ];
      db.query.mockResolvedValueOnce({ rows: mockEmployees, rowCount: mockEmployees.length });

      const res = await request(app).get('/api/employees');
      expect(res.statusCode).toBe(200);
      expect(res.body.data).toHaveLength(2);
      expect(res.body.count).toBe(2);
      expect(db.query).toHaveBeenCalledWith(expect.stringContaining('SELECT id, name'));
    });

    it('should handle database errors with 500 status', async () => {
      db.query.mockRejectedValueOnce(new Error('Database connection failed'));

      const res = await request(app).get('/api/employees');
      expect(res.statusCode).toBe(500);
      expect(res.body.error).toBe('Internal Server Error');
    });
  });

  describe('POST /api/employees', () => {
    const validEmployee = {
      name: 'John Doe',
      email: 'john.doe@example.com',
      department: 'DevOps',
      position: 'Senior Engineer',
      phone: '555-1234'
    };

    it('should create an employee and return 201', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 1, ...validEmployee, created_at: new Date(), updated_at: new Date() }],
        rowCount: 1
      });

      const res = await request(app)
        .post('/api/employees')
        .send(validEmployee);

      expect(res.statusCode).toBe(201);
      expect(res.body.message).toBe('Employee created successfully');
      expect(res.body.data.name).toBe('John Doe');
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO employees'),
        expect.arrayContaining(['John Doe', 'john.doe@example.com'])
      );
    });

    it('should fail with 400 when validation fails (missing fields)', async () => {
      const res = await request(app)
        .post('/api/employees')
        .send({ name: '' });

      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Validation Error');
      expect(res.body.details.length).toBeGreaterThan(0);
      expect(db.query).not.toHaveBeenCalled();
    });

    it('should fail with 400 when email format is invalid', async () => {
      const res = await request(app)
        .post('/api/employees')
        .send({ ...validEmployee, email: 'not-an-email' });

      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Validation Error');
      expect(db.query).not.toHaveBeenCalled();
    });

    it('should return 409 Conflict when email already exists', async () => {
      const duplicateError = new Error('duplicate key value violates unique constraint');
      duplicateError.code = '23505';
      db.query.mockRejectedValueOnce(duplicateError);

      const res = await request(app)
        .post('/api/employees')
        .send(validEmployee);

      expect(res.statusCode).toBe(409);
      expect(res.body.error).toBe('Conflict');
    });
  });

  describe('PUT /api/employees/:id', () => {
    const updatedEmployee = {
      name: 'Johnathan Doe',
      email: 'johnathan@example.com',
      department: 'DevOps',
      position: 'Lead Engineer',
      phone: '555-9999'
    };

    it('should update an existing employee and return 200', async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 1, ...updatedEmployee }],
        rowCount: 1
      });

      const res = await request(app)
        .put('/api/employees/1')
        .send(updatedEmployee);

      expect(res.statusCode).toBe(200);
      expect(res.body.message).toBe('Employee updated successfully');
      expect(res.body.data.name).toBe('Johnathan Doe');
    });

    it('should return 404 when employee ID is not found', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app)
        .put('/api/employees/999')
        .send(updatedEmployee);

      expect(res.statusCode).toBe(404);
      expect(res.body.error).toBe('Not Found');
    });

    it('should return 400 for invalid ID parameter', async () => {
      const res = await request(app)
        .put('/api/employees/abc')
        .send(updatedEmployee);

      expect(res.statusCode).toBe(400);
      expect(res.body.error).toBe('Validation Error');
    });
  });

  describe('DELETE /api/employees/:id', () => {
    it('should delete employee and return 200', async () => {
      db.query.mockResolvedValueOnce({ rows: [{ id: 1 }], rowCount: 1 });

      const res = await request(app).delete('/api/employees/1');
      expect(res.statusCode).toBe(200);
      expect(res.body.message).toContain('deleted successfully');
    });

    it('should return 404 when deleting non-existent employee', async () => {
      db.query.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const res = await request(app).delete('/api/employees/999');
      expect(res.statusCode).toBe(404);
      expect(res.body.error).toBe('Not Found');
    });
  });

  describe('404 Catch-All', () => {
    it('should return 404 for unknown endpoints', async () => {
      const res = await request(app).get('/api/unknown-endpoint');
      expect(res.statusCode).toBe(404);
      expect(res.body.error).toBe('Not Found');
    });
  });
});
