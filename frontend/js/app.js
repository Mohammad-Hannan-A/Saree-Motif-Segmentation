/**
 * app.js - Shared utilities, API client, and Octave health monitor
 * Saree Motif Segmentation Project
 */

const API_BASE = '/api';

// Toast Notification Manager
function showToast(message, type = 'info', duration = 4000) {
  let container = document.getElementById('toastContainer');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toastContainer';
    container.className = 'toast-container';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;

  let icon = 'ℹ️';
  if (type === 'success') icon = '✅';
  if (type === 'error') icon = '⚠️';

  toast.innerHTML = `<span>${icon}</span> <div>${message}</div>`;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

// Check Backend & GNU Octave Engine Health
async function checkEngineHealth() {
  const badge = document.getElementById('engineHealthBadge');
  if (!badge) return;

  try {
    const res = await fetch(`${API_BASE}/health`);
    if (!res.ok) throw new Error('Health check returned status ' + res.status);
    const data = await res.json();

    if (data.status === 'online' && data.octaveFound) {
      badge.innerHTML = `<span class="status-dot"></span> Octave Engine Active`;
      badge.title = `GNU Octave Path: ${data.octavePath}`;
      badge.style.borderColor = 'rgba(16, 185, 129, 0.4)';
      badge.style.color = '#10b981';
    } else {
      badge.innerHTML = `<span class="status-dot" style="background:#f59e0b;box-shadow:none"></span> Octave Not Detected`;
      badge.style.color = '#f59e0b';
    }
  } catch (err) {
    badge.innerHTML = `<span class="status-dot" style="background:#ef4444;box-shadow:none"></span> Backend Offline`;
    badge.style.color = '#ef4444';
  }
}

// Upload file helper
async function uploadImageFile(file) {
  const formData = new FormData();
  formData.append('image', file);

  const res = await fetch(`${API_BASE}/upload`, {
    method: 'POST',
    body: formData
  });

  const data = await res.json();
  if (!res.ok || !data.success) {
    throw new Error(data.error || 'Failed to upload image file');
  }

  return data.file;
}

// Fetch list of synthetic sample images
async function loadSampleImages(filterType = null) {
  try {
    const res = await fetch(`${API_BASE}/samples`);
    const data = await res.json();
    if (data.success && Array.isArray(data.samples)) {
      if (!filterType) return data.samples;
      return data.samples.filter(s => s.type === filterType);
    }
    return [];
  } catch (e) {
    console.error('Failed to load sample images:', e);
    return [];
  }
}

// Download image helper
function downloadFile(url, suggestedFilename = 'processed_saree.png') {
  const link = document.createElement('a');
  link.href = url;
  link.download = suggestedFilename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// Initialize on DOM load
document.addEventListener('DOMContentLoaded', () => {
  checkEngineHealth();
});
