import React, { useState, useEffect, useCallback } from 'react';
import './App.css';
import { api } from './services/api';
import Navbar from './components/Navbar';
import Alert from './components/Alert';
import Modal from './components/Modal';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import EmployeeList from './pages/EmployeeList';
import EmployeeForm from './pages/EmployeeForm';

function App() {
  // Authentication state (simple demo auth session)
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('bm_demo_user');
    return saved ? JSON.parse(saved) : null;
  });

  // Navigation state: 'dashboard' | 'employees' | 'add' | 'edit'
  const [activePage, setActivePage] = useState('dashboard');
  const [editingEmployee, setEditingEmployee] = useState(null);

  // Data & system state
  const [employees, setEmployees] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [systemHealth, setSystemHealth] = useState('unknown');

  // UI feedback states
  const [alert, setAlert] = useState({ type: '', message: '' });
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [isSaving, setIsSaving] = useState(false);

  // Clear alert helper
  const showAlert = (type, message) => {
    setAlert({ type, message });
    setTimeout(() => {
      setAlert({ type: '', message: '' });
    }, 5000);
  };

  // Fetch employees list from API
  const fetchEmployees = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await api.getEmployees();
      setEmployees(response.data || []);
    } catch (err) {
      showAlert('error', `Failed to load employees: ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Check backend health
  const checkHealth = useCallback(async () => {
    try {
      const res = await api.checkHealth();
      if (res.status === 'healthy') {
        setSystemHealth('healthy');
      } else {
        setSystemHealth('degraded');
      }
    } catch {
      setSystemHealth('offline');
    }
  }, []);

  // Initial load
  useEffect(() => {
    if (user) {
      fetchEmployees();
      checkHealth();
    }
  }, [user, fetchEmployees, checkHealth]);

  // Handle Login
  const handleLogin = (userData) => {
    localStorage.setItem('bm_demo_user', JSON.stringify(userData));
    setUser(userData);
    setActivePage('dashboard');
  };

  // Handle Logout
  const handleLogout = () => {
    localStorage.removeItem('bm_demo_user');
    setUser(null);
    setActivePage('dashboard');
  };

  // Open Edit Form
  const handleStartEdit = (employee) => {
    setEditingEmployee(employee);
    setActivePage('edit');
  };

  // Handle Save (Create or Update)
  const handleSaveEmployee = async (formData) => {
    setIsSaving(true);
    try {
      if (editingEmployee) {
        await api.updateEmployee(editingEmployee.id, formData);
        showAlert('success', `Employee "${formData.name}" updated successfully.`);
      } else {
        await api.createEmployee(formData);
        showAlert('success', `Employee "${formData.name}" added successfully.`);
      }
      await fetchEmployees();
      setActivePage('employees');
      setEditingEmployee(null);
    } catch (err) {
      showAlert('error', err.message);
    } finally {
      setIsSaving(false);
    }
  };

  // Handle Delete Confirmation
  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await api.deleteEmployee(deleteTarget.id);
      showAlert('success', `Employee "${deleteTarget.name}" deleted from database.`);
      setDeleteTarget(null);
      await fetchEmployees();
    } catch (err) {
      showAlert('error', `Failed to delete employee: ${err.message}`);
    }
  };

  // If not logged in, render Login view
  if (!user) {
    return <Login onLogin={handleLogin} />;
  }

  return (
    <div className="app-container">
      <Navbar
        activePage={activePage}
        setActivePage={(page) => {
          setEditingEmployee(null);
          setActivePage(page);
        }}
        user={user}
        onLogout={handleLogout}
      />

      <main className="main-content">
        <Alert
          type={alert.type}
          message={alert.message}
          onClose={() => setAlert({ type: '', message: '' })}
        />

        {activePage === 'dashboard' && (
          <Dashboard
            employees={employees}
            systemHealth={systemHealth}
            onNavigate={(page) => setActivePage(page)}
          />
        )}

        {activePage === 'employees' && (
          <EmployeeList
            employees={employees}
            isLoading={isLoading}
            onNavigate={(page) => setActivePage(page)}
            onEdit={handleStartEdit}
            onDeleteRequest={(emp) => setDeleteTarget(emp)}
          />
        )}

        {activePage === 'add' && (
          <EmployeeForm
            onSave={handleSaveEmployee}
            onCancel={() => setActivePage('employees')}
            isSaving={isSaving}
          />
        )}

        {activePage === 'edit' && (
          <EmployeeForm
            employee={editingEmployee}
            onSave={handleSaveEmployee}
            onCancel={() => {
              setEditingEmployee(null);
              setActivePage('employees');
            }}
            isSaving={isSaving}
          />
        )}
      </main>

      <Modal
        isOpen={Boolean(deleteTarget)}
        title="Confirm Deletion"
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
        confirmText="Delete Employee"
        confirmStyle="danger"
      >
        Are you sure you want to delete <strong>{deleteTarget?.name}</strong> (ID: #{deleteTarget?.id}) from the database? This action cannot be undone.
      </Modal>
    </div>
  );
}

export default App;
