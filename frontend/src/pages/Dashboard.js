import React from 'react';

export default function Dashboard({ employees, systemHealth, onNavigate }) {
  const totalEmployees = employees.length;
  const uniqueDepartments = Array.from(new Set(employees.map(e => e.department).filter(Boolean)));
  const recentEmployees = [...employees].slice(-5).reverse();

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Executive Dashboard</h1>
          <p className="page-subtitle">Real-time Enterprise metrics and workforce status</p>
        </div>
        <button
          className="btn btn-primary"
          onClick={() => onNavigate('add')}
        >
          + Add New Employee
        </button>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-label">Total Employees</div>
          <div className="stat-value">{totalEmployees}</div>
        </div>

        <div className="stat-card">
          <div className="stat-label">Departments</div>
          <div className="stat-value">{uniqueDepartments.length}</div>
        </div>

        <div className="stat-card">
          <div className="stat-label">Backend Health</div>
          <div className="stat-value" style={{ fontSize: '1.5rem', marginTop: '1rem', color: systemHealth === 'healthy' ? '#10b981' : '#f59e0b' }}>
            {systemHealth === 'healthy' ? '● Healthy (ALB OK)' : '○ Checking / Offline'}
          </div>
        </div>
      </div>

      <div className="page-header" style={{ marginBottom: '1rem' }}>
        <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Recent Employees</h2>
        <button
          className="btn btn-secondary btn-sm"
          onClick={() => onNavigate('employees')}
        >
          View All ({totalEmployees})
        </button>
      </div>

      <div className="table-container">
        {recentEmployees.length === 0 ? (
          <div className="empty-box">
            No employees registered yet. Click "+ Add New Employee" to get started!
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
              </tr>
            </thead>
            <tbody>
              {recentEmployees.map((emp) => (
                <tr key={emp.id}>
                  <td><strong>#{emp.id}</strong></td>
                  <td>{emp.name}</td>
                  <td>{emp.email}</td>
                  <td><span className="badge">{emp.department}</span></td>
                  <td>{emp.position}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
