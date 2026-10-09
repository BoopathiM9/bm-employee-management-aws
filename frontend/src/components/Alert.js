import React from 'react';

export default function Alert({ type = 'error', message, onClose }) {
  if (!message) return null;

  return (
    <div className={`alert ${type === 'success' ? 'alert-success' : 'alert-error'}`}>
      <span>{message}</span>
      {onClose && (
        <button
          onClick={onClose}
          style={{ background: 'none', border: 'none', cursor: 'pointer', fontWeight: 'bold' }}
        >
          ×
        </button>
      )}
    </div>
  );
}
