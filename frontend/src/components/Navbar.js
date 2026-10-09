import React from 'react';

export default function Navbar({ activePage, setActivePage, user, onLogout }) {
  return (
    <header className="navbar">
      <div className="nav-brand" onClick={() => setActivePage('dashboard')}>
        <span>BM Enterprise</span>
      </div>

      <nav className="nav-links">
        <button
          className={`nav-link ${activePage === 'dashboard' ? 'active' : ''}`}
          onClick={() => setActivePage('dashboard')}
        >
          Dashboard
        </button>
        <button
          className={`nav-link ${activePage === 'employees' || activePage === 'add' || activePage === 'edit' ? 'active' : ''}`}
          onClick={() => setActivePage('employees')}
        >
          Employees
        </button>

        <div className="nav-user">
          <div className="user-avatar" title={user?.email || 'User'}>
            {(user?.name || 'A')[0].toUpperCase()}
          </div>
          <button className="nav-link" onClick={onLogout} title="Sign Out">
            Logout
          </button>
        </div>
      </nav>
    </header>
  );
}
