/**
 * API Service for BM Employee Management System.
 * Connects to live AWS backend, with seamless fallback for static hosts (Vercel)
 * or when AWS infrastructure is powered down.
 */

const API_BASE_URL = process.env.REACT_APP_API_URL !== undefined
  ? process.env.REACT_APP_API_URL
  : (process.env.NODE_ENV === 'production' ? '' : 'http://localhost:8080');

const LOCAL_STORAGE_KEY = 'bm_employee_records';

function getLocalStore() {
  try {
    const raw = localStorage.getItem(LOCAL_STORAGE_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {}

  const initialSeed = [
    {
      id: 1,
      name: 'Boopathi Murugesan',
      email: 'boopathi@enterprise.cloud',
      department: 'Cloud Architecture & DevOps',
      position: 'Lead Cloud Architect',
      phone: '+1-555-0199',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  ];
  saveLocalStore(initialSeed);
  return initialSeed;
}

function saveLocalStore(records) {
  try {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(records));
  } catch (e) {}
}

async function request(endpoint, options = {}) {
  const url = `${API_BASE_URL}${endpoint}`;
  const config = {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...options.headers
    }
  };

  try {
    const response = await fetch(url, config);

    // If static host returns 405 Method Not Allowed or 404
    if (response.status === 405 || response.status === 404) {
      return handleOfflineFallback(endpoint, options);
    }

    if (response.status === 204) {
      return { success: true };
    }

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const msg = data.details ? data.details.join(', ') : (data.message || data.error || `HTTP error ${response.status}`);
      throw new Error(msg);
    }

    return data;
  } catch (error) {
    // If backend is unreachable or Method Not Allowed, fallback gracefully
    if (error.message.includes('405') || error.message.includes('Failed to fetch')) {
      return handleOfflineFallback(endpoint, options);
    }
    throw error;
  }
}

function handleOfflineFallback(endpoint, options) {
  const method = (options.method || 'GET').toUpperCase();
  const records = getLocalStore();

  if (endpoint.startsWith('/health')) {
    return { status: 'healthy', mode: 'demo-storage' };
  }

  // GET /api/employees
  if (endpoint === '/api/employees' && method === 'GET') {
    return { data: records, count: records.length };
  }

  // POST /api/employees
  if (endpoint === '/api/employees' && method === 'POST') {
    const body = options.body ? JSON.parse(options.body) : {};
    const newRecord = {
      id: Date.now(),
      name: body.name || 'Employee',
      email: body.email || '',
      department: body.department || 'General',
      position: body.position || 'Staff',
      phone: body.phone || '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    records.push(newRecord);
    saveLocalStore(records);
    return { message: 'Employee created successfully', data: newRecord };
  }

  // PUT /api/employees/:id
  const matchId = endpoint.match(/\/api\/employees\/(\d+)/);
  if (matchId) {
    const id = parseInt(matchId[1], 10);
    const index = records.findIndex(r => r.id === id);

    if (method === 'PUT') {
      if (index === -1) throw new Error('Employee not found');
      const body = options.body ? JSON.parse(options.body) : {};
      const updated = {
        ...records[index],
        ...body,
        updated_at: new Date().toISOString()
      };
      records[index] = updated;
      saveLocalStore(records);
      return { message: 'Employee updated successfully', data: updated };
    }

    if (method === 'DELETE') {
      if (index === -1) throw new Error('Employee not found');
      records.splice(index, 1);
      saveLocalStore(records);
      return { message: `Employee with ID ${id} deleted successfully.` };
    }

    if (method === 'GET') {
      if (index === -1) throw new Error('Employee not found');
      return { data: records[index] };
    }
  }

  return { data: records, count: records.length };
}

export const api = {
  checkHealth: () => request('/health'),
  getEmployees: () => request('/api/employees'),
  getEmployee: (id) => request(`/api/employees/${id}`),
  createEmployee: (data) => request('/api/employees', { method: 'POST', body: JSON.stringify(data) }),
  updateEmployee: (id, data) => request(`/api/employees/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  deleteEmployee: (id) => request(`/api/employees/${id}`, { method: 'DELETE' }),
  getBaseUrl: () => API_BASE_URL
};
