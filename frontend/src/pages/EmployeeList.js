import React, { useState } from 'react';

export default function EmployeeList({
  employees,
  isLoading,
  onNavigate,
  onEdit,
  onDeleteRequest
}) {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredEmployees = employees.filter((emp) => {
    const term = searchTerm.toLowerCase();
    return (
      emp.name?.toLowerCase().includes(term) ||
      emp.email?.toLowerCase().includes(term) ||
      emp.department?.toLowerCase().includes(term) ||
      emp.position?.toLowerCase().includes(term)
    );
  });

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Employee Directory</h1>
          <p className="page-subtitle">Manage organization personnel, records, and departmental roles</p>
        </div>
        <button className="btn btn-primary" onClick={() => onNavigate('add')}>
          + Add Employee
        </button>
      </div>

      <div style={{ marginBottom: '1.25rem', display: 'flex', gap: '1rem', alignItems: 'center' }}>
        <input
          type="text"
          className="form-input"
          style={{ maxWidth: '350px' }}
          placeholder="Search by name, email, or department..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        <span style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>
          Showing {filteredEmployees.length} of {employees.length} employees
        </span>
      </div>

      <div className="table-container">
        {isLoading ? (
          <div className="loading-box">Loading employees from database...</div>
        ) : filteredEmployees.length === 0 ? (
          <div className="empty-box">
            {searchTerm ? 'No employees matched your search.' : 'No employees found in database.'}
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Department</th>
                <th>Position</th>
                <th>Phone</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredEmployees.map((emp) => (
                <tr key={emp.id}>
                  <td><strong>#{emp.id}</strong></td>
                  <td style={{ fontWeight: 500 }}>{emp.name}</td>
                  <td>{emp.email}</td>
                  <td><span className="badge">{emp.department}</span></td>
                  <td>{emp.position}</td>
                  <td>{emp.phone || '—'}</td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.5rem' }}>
                      <button
                        className="btn btn-secondary btn-sm"
                        onClick={() => onEdit(emp)}
                      >
                        Edit
                      </button>
                      <button
                        className="btn btn-danger btn-sm"
                        onClick={() => onDeleteRequest(emp)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
