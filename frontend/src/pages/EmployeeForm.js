import React, { useState, useEffect } from 'react';

export default function EmployeeForm({ employee, onSave, onCancel, isSaving }) {
  const isEditing = Boolean(employee && employee.id);

  const [formData, setFormData] = useState({
    name: '',
    email: '',
    department: '',
    position: '',
    phone: ''
  });
  const [error, setError] = useState('');

  useEffect(() => {
    if (employee) {
      setFormData({
        name: employee.name || '',
        email: employee.email || '',
        department: employee.department || '',
        position: employee.position || '',
        phone: employee.phone || ''
      });
    }
  }, [employee]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setError('');

    if (!formData.name.trim()) {
      setError('Employee name is required.');
      return;
    }
    if (!formData.email.trim() || !formData.email.includes('@')) {
      setError('A valid email address is required.');
      return;
    }
    if (!formData.department.trim()) {
      setError('Department is required.');
      return;
    }
    if (!formData.position.trim()) {
      setError('Position/Title is required.');
      return;
    }

    onSave(formData);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">{isEditing ? `Edit Employee #${employee.id}` : 'Add New Employee'}</h1>
          <p className="page-subtitle">
            {isEditing ? 'Update personnel records and assignment' : 'Register a new employee into the organization directory'}
          </p>
        </div>
        <button className="btn btn-secondary" onClick={onCancel} disabled={isSaving}>
          ← Back to Directory
        </button>
      </div>

      <div className="form-card">
        {error && (
          <div className="alert alert-error">
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Full Name *</label>
            <input
              type="text"
              name="name"
              className="form-input"
              value={formData.name}
              onChange={handleChange}
              placeholder="e.g. Jane Doe"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Email Address *</label>
            <input
              type="email"
              name="email"
              className="form-input"
              value={formData.email}
              onChange={handleChange}
              placeholder="e.g. jane.doe@example.com"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Department *</label>
            <input
              type="text"
              name="department"
              className="form-input"
              value={formData.department}
              onChange={handleChange}
              placeholder="e.g. Cloud Infrastructure / DevOps"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Position / Job Title *</label>
            <input
              type="text"
              name="position"
              className="form-input"
              value={formData.position}
              onChange={handleChange}
              placeholder="e.g. Senior AWS Solutions Architect"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Phone Number</label>
            <input
              type="tel"
              name="phone"
              className="form-input"
              value={formData.phone}
              onChange={handleChange}
              placeholder="e.g. +1 (555) 019-2834"
            />
          </div>

          <div className="form-actions">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onCancel}
              disabled={isSaving}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={isSaving}
            >
              {isSaving ? 'Saving to Database...' : isEditing ? 'Update Employee' : 'Create Employee'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
