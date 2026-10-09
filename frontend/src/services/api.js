/**
 * API Service for BM Employee Management System.
 * Supports configurable API Base URL via REACT_APP_API_URL.
 */
const API_BASE_URL = process.env.REACT_APP_API_URL !== undefined
  ? process.env.REACT_APP_API_URL
  : (process.env.NODE_ENV === 'production' ? '' : 'http://localhost:8080');

async function request(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;
  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };

  const config = {
    ...options,
    headers: {
      ...defaultHeaders,
      ...options.headers
    }
  };

  try {
    const response = await fetch(url, config);

    // Handle 204 No Content
    if (response.status === 204) {
      return { success: true };
    }

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errorMessage = data.details
        ? data.details.join(', ')
        : (data.message || data.error || `HTTP error ${response.status}`);
      throw new Error(errorMessage);
    }

    return data;
  } catch (error) {
    console.error(`[API Error] ${options.method || 'GET'} ${url}:`, error.message);
    throw error;
  }
}

export const api = {
  // Health check
  checkHealth: () => request('/health'),

  // Employee CRUD operations
  getEmployees: () => request('/api/employees'),
  getEmployee: (id) => request(`/api/employees/${id}`),
  createEmployee: (employeeData) => request('/api/employees', {
    method: 'POST',
    body: JSON.stringify(employeeData)
  }),
  updateEmployee: (id, employeeData) => request(`/api/employees/${id}`, {
    method: 'PUT',
    body: JSON.stringify(employeeData)
  }),
  deleteEmployee: (id) => request(`/api/employees/${id}`, {
    method: 'DELETE'
  }),

  getBaseUrl: () => API_BASE_URL
};
