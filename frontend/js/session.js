/**
 * session.js
 * Persistent State and Workflow Navigation Management for
 * Saree Motif Segmentation Using Image Processing.
 *
 * Preserves uploaded images, grayscale conversions, intermediate Page 2/3 outputs,
 * bounding boxes, masks, extracted motifs, and composited results across page navigation.
 */

const SESSION_STORAGE_KEY = 'saree_motif_session_v2';

class SessionManager {
  constructor() {
    this.session = this.loadSession();
    this.ensureSessionId();
  }

  loadSession() {
    try {
      const stored = localStorage.getItem(SESSION_STORAGE_KEY);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (e) {
      console.warn('Failed to parse stored session:', e);
    }

    return {
      id: this.generateId(),
      createdAt: new Date().toISOString(),
      originalImage: null,    // { url, path, filename, name }
      grayscaleImage: null,   // { url, path, filename }
      page2Results: [],       // Array of { id, algorithm, title, url, path, filename, params, timestamp }
      page3Results: [],       // Array of { id, method, algorithm, title, url, path, filename, params, timestamp }
      page4Data: {
        selectedSource: null,
        bboxCrop: null,
        rawMask: null,
        refinedMask: null,
        extractedMotif: null,
        composite: null
      }
    };
  }

  saveSession() {
    try {
      localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(this.session));
    } catch (e) {
      console.error('Failed to save session to localStorage:', e);
    }
  }

  generateId() {
    return 'SES_' + Math.random().toString(36).substring(2, 9).toUpperCase() + '_' + Date.now().toString().slice(-4);
  }

  ensureSessionId() {
    if (!this.session.id) {
      this.session.id = this.generateId();
      this.saveSession();
    }
  }

  resetSession() {
    localStorage.removeItem(SESSION_STORAGE_KEY);
    this.session = this.loadSession();
    this.saveSession();
    window.location.href = 'page1.html';
  }

  setOriginalImage(imgData) {
    this.session.originalImage = imgData;
    this.saveSession();
  }

  getOriginalImage() {
    return this.session.originalImage;
  }

  setGrayscaleImage(imgData) {
    this.session.grayscaleImage = imgData;
    this.saveSession();
  }

  getGrayscaleImage() {
    return this.session.grayscaleImage;
  }

  addPage2Result(result) {
    if (!this.session.page2Results) this.session.page2Results = [];
    // Prevent duplicate entries for same algorithm run if identical URL
    const existingIdx = this.session.page2Results.findIndex(r => r.url === result.url);
    if (existingIdx >= 0) {
      this.session.page2Results[existingIdx] = result;
    } else {
      this.session.page2Results.push(result);
    }
    this.saveSession();
  }

  getPage2Results() {
    return this.session.page2Results || [];
  }

  addPage3Result(result) {
    if (!this.session.page3Results) this.session.page3Results = [];
    const existingIdx = this.session.page3Results.findIndex(r => r.url === result.url);
    if (existingIdx >= 0) {
      this.session.page3Results[existingIdx] = result;
    } else {
      this.session.page3Results.push(result);
    }
    this.saveSession();
  }

  getPage3Results() {
    return this.session.page3Results || [];
  }

  updatePage4Data(key, value) {
    if (!this.session.page4Data) this.session.page4Data = {};
    this.session.page4Data[key] = value;
    this.saveSession();
  }

  getPage4Data() {
    return this.session.page4Data || {};
  }

  /**
   * Retrieves all available source images in the session for selection in dropdowns.
   * Includes original image, grayscale image, page 2 results, and page 3 results.
   */
  getAllSelectableImages() {
    const list = [];

    if (this.session.originalImage) {
      list.push({
        id: 'orig',
        title: 'Original Saree Image (Color)',
        category: 'Page 1 - Original',
        url: this.session.originalImage.url,
        path: this.session.originalImage.path,
        filename: this.session.originalImage.filename
      });
    }

    if (this.session.grayscaleImage) {
      list.push({
        id: 'gray',
        title: 'Grayscale Converted Image',
        category: 'Page 1 - Grayscale',
        url: this.session.grayscaleImage.url,
        path: this.session.grayscaleImage.path,
        filename: this.session.grayscaleImage.filename
      });
    }

    (this.session.page2Results || []).forEach((res, idx) => {
      list.push({
        id: `p2_${idx}`,
        title: `${res.title || res.algorithm} (Page 2)`,
        category: 'Page 2 Results',
        url: res.url,
        path: res.path || res.outputPath,
        filename: res.filename
      });
    });

    (this.session.page3Results || []).forEach((res, idx) => {
      list.push({
        id: `p3_${idx}`,
        title: `${res.title || res.algorithm} (Page 3)`,
        category: 'Page 3 Results',
        url: res.url,
        path: res.path || res.outputPath,
        filename: res.filename
      });
    });

    return list;
  }

  /**
   * Validates if navigation to a specific page is permitted based on current state.
   */
  canNavigateTo(targetPageNum) {
    if (targetPageNum === 1) return { allowed: true };

    if (!this.session.originalImage) {
      return {
        allowed: false,
        reason: 'Please upload an image and convert it to grayscale on Page 1 before proceeding.'
      };
    }

    if (targetPageNum >= 3 && !this.session.originalImage) {
      return {
        allowed: false,
        reason: 'Missing original image. Please complete Page 1 first.'
      };
    }

    return { allowed: true };
  }

  /**
   * Navigates safely to target page with guard checking.
   */
  navigateTo(targetPageNum) {
    const check = this.canNavigateTo(targetPageNum);
    if (!check.allowed) {
      this.showToast(check.reason, 'error');
      return false;
    }
    window.location.href = `page${targetPageNum}.html`;
    return true;
  }

  showToast(message, type = 'info') {
    let container = document.getElementById('toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'toast-container';
      container.className = 'toast-container';
      document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.className = `toast-item toast-${type}`;
    const icon = type === 'success' ? '✓' : type === 'error' ? '⚠' : 'ℹ';
    toast.innerHTML = `
      <span class="toast-icon">${icon}</span>
      <span class="toast-message">${message}</span>
      <button class="toast-close" onclick="this.parentElement.remove()">×</button>
    `;

    container.appendChild(toast);
    setTimeout(() => {
      toast.classList.add('fade-out');
      setTimeout(() => toast.remove(), 400);
    }, 4500);
  }

  /**
   * Initializes the common navigation header across all pages.
   */
  initHeader(currentPageNum) {
    const headerContainer = document.getElementById('app-header');
    if (!headerContainer) return;

    headerContainer.innerHTML = `
      <div class="header-top">
        <div class="brand">
          <div class="brand-logo">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
            </svg>
          </div>
          <div>
            <h1 class="brand-title">Saree Motif Segmentation Using Image Processing</h1>
            <p class="brand-subtitle">GNU Octave Academic Image Processing Suite</p>
          </div>
        </div>

        <div class="header-status">
          <div class="engine-badge" id="octave-status-badge">
            <span class="status-dot pulsing"></span>
            <span id="octave-status-text">Checking Octave...</span>
          </div>
          <div class="session-badge">
            <span class="badge-label">Session:</span>
            <span class="badge-val">${this.session.id}</span>
          </div>
          <button class="btn btn-outline-sm" id="btn-reset-session" title="Start a fresh session">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
              <path d="M3 3v5h5"/>
            </svg>
            Reset
          </button>
        </div>
      </div>

      <!-- 4-Step Progress Navigation Bar -->
      <nav class="steps-nav" aria-label="Workflow Steps">
        <div class="step-item ${currentPageNum === 1 ? 'active' : ''} ${this.session.originalImage ? 'completed' : ''}" onclick="window.sareeSession.navigateTo(1)">
          <div class="step-num">1</div>
          <div class="step-details">
            <div class="step-name">Image Upload & Grayscale</div>
            <div class="step-desc">Input Saree & RGB to Gray</div>
          </div>
        </div>

        <div class="step-connector ${this.session.originalImage ? 'active' : ''}"></div>

        <div class="step-item ${currentPageNum === 2 ? 'active' : ''} ${(this.session.page2Results && this.session.page2Results.length > 0) ? 'completed' : ''}" onclick="window.sareeSession.navigateTo(2)">
          <div class="step-num">2</div>
          <div class="step-details">
            <div class="step-name">6 Basic Algorithms</div>
            <div class="step-desc">Negative, Resizing, HSV, etc.</div>
          </div>
        </div>

        <div class="step-connector ${(this.session.page2Results && this.session.page2Results.length > 0) ? 'active' : ''}"></div>

        <div class="step-item ${currentPageNum === 3 ? 'active' : ''} ${(this.session.page3Results && this.session.page3Results.length > 0) ? 'completed' : ''}" onclick="window.sareeSession.navigateTo(3)">
          <div class="step-num">3</div>
          <div class="step-details">
            <div class="step-name">4 Advanced Methods</div>
            <div class="step-desc">Enhancement, Segmentation, Edges, Morphology</div>
          </div>
        </div>

        <div class="step-connector ${(this.session.page3Results && this.session.page3Results.length > 0) ? 'active' : ''}"></div>

        <div class="step-item ${currentPageNum === 4 ? 'active' : ''} ${this.session.page4Data && this.session.page4Data.extractedMotif ? 'completed' : ''}" onclick="window.sareeSession.navigateTo(4)">
          <div class="step-num">4</div>
          <div class="step-details">
            <div class="step-name">Motif Extraction & Composition</div>
            <div class="step-desc">Crop, Transparent PNG & Placement</div>
          </div>
        </div>
      </nav>
    `;

    // Connect Reset button
    const btnReset = document.getElementById('btn-reset-session');
    if (btnReset) {
      btnReset.addEventListener('click', () => {
        if (confirm('Are you sure you want to reset your workflow session? This will clear all uploaded images and intermediate results.')) {
          this.resetSession();
        }
      });
    }

    // Check backend health
    this.checkHealth();
  }

  async checkHealth() {
    const badge = document.getElementById('octave-status-badge');
    const text = document.getElementById('octave-status-text');
    if (!badge || !text) return;

    try {
      const res = await fetch('/api/health');
      const data = await res.json();
      if (data.status === 'online') {
        text.textContent = 'GNU Octave Connected';
        badge.classList.remove('error');
        badge.classList.add('online');
      } else {
        text.textContent = 'Octave Offline';
        badge.classList.add('error');
      }
    } catch (err) {
      text.textContent = 'Server Disconnected';
      badge.classList.add('error');
    }
  }
}

// Global instance
window.sareeSession = new SessionManager();
