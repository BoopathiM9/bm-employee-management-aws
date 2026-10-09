import React, { useState } from 'react';

export default function Login({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isVerifying, setIsVerifying] = useState(false);

  // SHA-256 hash of authorized password (ensures plaintext is never exposed in GitHub code)
  const AUTH_HASH = '5e4fc8f86c3f4eb54c57cbb3ac78ee49ce1cf93c76b1d4428ee5c42abf883770';

  const verifyPassword = async (pwd) => {
    try {
      if (window.crypto && window.crypto.subtle) {
        const buffer = new TextEncoder().encode(pwd);
        const hashBuffer = await window.crypto.subtle.digest('SHA-256', buffer);
        const hashHex = Array.from(new Uint8Array(hashBuffer))
          .map((b) => b.toString(16).padStart(2, '0'))
          .join('');
        return hashHex === AUTH_HASH;
      }
      return false;
    } catch {
      return false;
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    const trimmedUser = email.trim().toLowerCase();

    if (!trimmedUser || !password) {
      setError('Please provide both username and password.');
      return;
    }

    setIsVerifying(true);
    try {
      const isPasswordValid = await verifyPassword(password);
      const isUserValid = trimmedUser === 'admin';

      if (!isUserValid || !isPasswordValid) {
        setError('Invalid username or password.');
        setIsVerifying(false);
        return;
      }

      onLogin({
        email: 'admin@enterprise.internal',
        name: 'Administrator',
        role: 'System Administrator'
      });
    } catch (err) {
      setError('Authentication failed. Please try again.');
    } finally {
      setIsVerifying(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <div className="login-header">
          <h1 className="login-title">BM Portal</h1>
          <p className="login-desc">Sign in to Employee Management System</p>
        </div>

        {error && (
          <div className="alert alert-error">
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Username</label>
            <input
              type="text"
              className="form-input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter username"
              autoComplete="username"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <input
              type="password"
              className="form-input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter password"
              autoComplete="current-password"
              required
            />
          </div>

          <div style={{ marginTop: '1.5rem' }}>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={isVerifying}
              style={{ width: '100%', padding: '0.75rem', opacity: isVerifying ? 0.7 : 1 }}
            >
              {isVerifying ? 'Verifying...' : 'Sign In'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
