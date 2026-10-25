/**
 * page3.js - Logic for Page 3: Four Image-Processing Methods
 * Communicates with GNU Octave backend via /api/process.
 */

document.addEventListener('DOMContentLoaded', () => {
  // Navigation guard
  const check = window.sareeSession.canNavigateTo(3);
  if (!check.allowed) {
    alert(check.reason);
    window.location.href = 'page1.html';
    return;
  }

  // Initialize Header Navigation for Step 3
  window.sareeSession.initHeader(3);

  // Method Definitions Database
  const METHODS_CONFIG = {
    enhancement: {
      title: 'Method 1: Image Enhancement',
      subAlgorithms: [
        {
          id: 'histogram_equalization',
          name: 'Histogram Equalization',
          desc: 'Flattens probability density function across [0, 255] via Cumulative Distribution Function (CDF).',
          params: []
        },
        {
          id: 'contrast_stretching',
          name: 'Contrast Stretching',
          desc: 'Linearly scales dynamic range using 1% and 99% percentile clipping bounds.',
          params: [
            { id: 'lowClip', label: 'Lower Percentile', type: 'number', default: 0.01, step: 0.01, min: 0, max: 0.2 },
            { id: 'highClip', label: 'Upper Percentile', type: 'number', default: 0.99, step: 0.01, min: 0.8, max: 1.0 }
          ]
        },
        {
          id: 'median_filtering',
          name: 'Median Filtering',
          desc: 'Non-linear order-statistics filter that eliminates salt-and-pepper fabric noise while retaining crisp edges.',
          params: [
            { id: 'windowSize', label: 'Window Size (NxN)', type: 'select', default: 3, options: [
              { val: 3, label: '3 × 3 (Gentle Denoise)' },
              { val: 5, label: '5 × 5 (Moderate Denoise)' },
              { val: 7, label: '7 × 7 (Heavy Denoise)' }
            ]}
          ]
        }
      ]
    },
    segmentation: {
      title: 'Method 2: Image Segmentation',
      subAlgorithms: [
        {
          id: 'kmeans_segmentation',
          name: 'K-Means Clustering Segmentation',
          desc: 'Unsupervised partitioning of pixel chromatic feature vectors into K discrete clusters via Lloyd minimization.',
          params: [
            { id: 'numClusters', label: 'Number of Color Clusters (K)', type: 'select', default: 3, options: [
              { val: 2, label: 'K = 2 (Foreground vs Background)' },
              { val: 3, label: 'K = 3 (Silk, Zari, Shadows)' },
              { val: 4, label: 'K = 4 (Multi-tone Embroidery)' },
              { val: 5, label: 'K = 5 (Complex Pattern)' }
            ]},
            { id: 'maxIterations', label: 'Max Iterations', type: 'number', default: 15, min: 5, max: 50 }
          ]
        },
        {
          id: 'region_based_segmentation',
          name: 'Region-Based Segmentation',
          desc: '4-connected seeded region growing merging contiguous pixels whose color difference is below tolerance.',
          params: [
            { id: 'tolerance', label: 'Color Similarity Tolerance', type: 'range', default: 35, min: 10, max: 100 }
          ]
        },
        {
          id: 'color_based_segmentation',
          name: 'Color-Based Segmentation',
          desc: 'Isolates motif pixels matching a reference color within a Euclidean color-space tolerance radius.',
          params: [
            { id: 'targetPreset', label: 'Target Motif Color Preset', type: 'select', default: 'gold', options: [
              { val: 'gold', label: 'Traditional Gold Zari [218, 165, 32]' },
              { val: 'ruby', label: 'Ruby / Maroon Silk [155, 17, 30]' },
              { val: 'emerald', label: 'Emerald Green Border [9, 121, 105]' },
              { val: 'sapphire', label: 'Royal Sapphire Blue [20, 24, 82]' }
            ]},
            { id: 'tolerance', label: 'Distance Tolerance Radius', type: 'range', default: 55, min: 15, max: 120 }
          ]
        }
      ]
    },
    edge: {
      title: 'Method 3: Edge Detection',
      subAlgorithms: [
        {
          id: 'sobel_edge_detection',
          name: 'Sobel Edge Detection',
          desc: 'Computes spatial intensity derivatives using smoothed 3x3 horizontal and vertical Sobel gradient kernels.',
          params: [
            { id: 'threshold', label: 'Gradient Cutoff Threshold', type: 'range', default: 50, min: 10, max: 180 }
          ]
        },
        {
          id: 'prewitt_edge_detection',
          name: 'Prewitt Edge Detection',
          desc: 'Computes directional spatial derivatives with equal-weight 3x3 Prewitt convolution masks.',
          params: [
            { id: 'threshold', label: 'Gradient Cutoff Threshold', type: 'range', default: 45, min: 10, max: 180 }
          ]
        },
        {
          id: 'canny_edge_detection',
          name: 'Canny Edge Detection',
          desc: 'Four-stage optimal detector: Gaussian smoothing, gradient calculation, non-maximum suppression, and hysteresis tracking.',
          params: [
            { id: 'sigma', label: 'Gaussian Filter Sigma (σ)', type: 'number', default: 1.4, step: 0.2, min: 0.6, max: 3.0 }
          ]
        }
      ]
    },
    morphology: {
      title: 'Method 4: Morphological Processing',
      subAlgorithms: [
        {
          id: 'morphological_dilation',
          name: 'Morphological Dilation',
          desc: 'Expands bright foreground regions using a Structuring Element to bridge gaps in thin zari motif borders.',
          params: [
            { id: 'seShape', label: 'Structuring Element Shape', type: 'select', default: 'disk', options: [
              { val: 'disk', label: 'Disk (Isotropic / Smooth)' },
              { val: 'square', label: 'Square (Grid-aligned)' },
              { val: 'diamond', label: 'Diamond' }
            ]},
            { id: 'seSize', label: 'SE Radius / Size', type: 'number', default: 2, min: 1, max: 10 }
          ]
        },
        {
          id: 'morphological_erosion',
          name: 'Morphological Erosion',
          desc: 'Shrinks bright objects to strip away extraneous thread whiskers and eliminate isolated background noise specks.',
          params: [
            { id: 'seShape', label: 'Structuring Element Shape', type: 'select', default: 'disk', options: [
              { val: 'disk', label: 'Disk (Isotropic / Smooth)' },
              { val: 'square', label: 'Square' },
              { val: 'diamond', label: 'Diamond' }
            ]},
            { id: 'seSize', label: 'SE Radius / Size', type: 'number', default: 2, min: 1, max: 10 }
          ]
        },
        {
          id: 'morphological_open_close',
          name: 'Opening & Closing',
          desc: 'Opening (erosion then dilation) removes external background specks; Closing (dilation then erosion) seals internal holes.',
          params: [
            { id: 'operation', label: 'Morphological Sequence', type: 'select', default: 'both', options: [
              { val: 'both', label: 'Both (Open then Close - Full Refine)' },
              { val: 'opening', label: 'Opening Only (Denoise & Detach)' },
              { val: 'closing', label: 'Closing Only (Seal Holes & Bridges)' }
            ]},
            { id: 'seShape', label: 'Structuring Element Shape', type: 'select', default: 'disk', options: [
              { val: 'disk', label: 'Disk' },
              { val: 'square', label: 'Square' }
            ]},
            { id: 'seSize', label: 'SE Radius', type: 'number', default: 2, min: 1, max: 8 }
          ]
        }
      ]
    }
  };

  // State
  let activeMethodKey = 'enhancement';
  let activeSubAlgoId = 'histogram_equalization';
  let currentSelectedSource = null;
  let lastOutputResult = null;

  // UI Elements
  const sourceImageSelect = document.getElementById('source-image-select');
  const sourceInfoText = document.getElementById('source-info-text');
  const methodCards = document.querySelectorAll('.method-card');
  const activeMethodTitle = document.getElementById('active-method-title');
  const subAlgoSelect = document.getElementById('sub-algo-select');
  const subAlgoMathDesc = document.getElementById('sub-algo-math-desc');
  const dynamicParamsContainer = document.getElementById('dynamic-params-container');
  const btnApplyMethod = document.getElementById('btn-apply-method');
  const beforeImg = document.getElementById('before-img');
  const afterImg = document.getElementById('after-img');
  const afterEmpty = document.getElementById('after-empty');
  const executionMetaText = document.getElementById('execution-meta-text');
  const btnDownloadResult = document.getElementById('btn-download-result');
  const btnSaveAsInput = document.getElementById('btn-save-as-input');
  const btnBackPage2 = document.getElementById('btn-back-page2');
  const btnContinueMotif = document.getElementById('btn-continue-motif');
  const p3ResultsGallery = document.getElementById('p3-results-gallery');
  const p3GallerySubtitle = document.getElementById('p3-gallery-subtitle');
  const loadingOverlay = document.getElementById('loading-overlay');
  const loadingTitle = document.getElementById('loading-title');
  const loadingDesc = document.getElementById('loading-desc');

  // Initialize
  populateSourceDropdown();
  setupMethodCardSelection();
  renderActiveMethodControls();
  restoreP3Gallery();

  // Source Selector Change
  sourceImageSelect.addEventListener('change', () => {
    onSourceSelectionChanged();
  });

  // Sub-algorithm Dropdown Change
  subAlgoSelect.addEventListener('change', () => {
    activeSubAlgoId = subAlgoSelect.value;
    renderSubAlgoParams();
  });

  // Navigation
  btnBackPage2.addEventListener('click', () => {
    window.location.href = 'page2.html';
  });

  btnContinueMotif.addEventListener('click', () => {
    window.location.href = 'page4.html';
  });

  // Reuse as Input
  btnSaveAsInput.addEventListener('click', () => {
    if (lastOutputResult) {
      populateSourceDropdown(lastOutputResult.id);
      window.sareeSession.showToast(`Selected "${lastOutputResult.title}" as input for subsequent operations!`, 'info');
    }
  });

  // Download Result
  btnDownloadResult.addEventListener('click', () => {
    if (lastOutputResult && lastOutputResult.filename) {
      window.location.href = `/api/download/${lastOutputResult.filename}`;
    }
  });

  // Apply Button Click
  btnApplyMethod.addEventListener('click', async () => {
    if (!currentSelectedSource || !currentSelectedSource.path) {
      window.sareeSession.showToast('Please select a valid source image.', 'error');
      return;
    }

    const subAlgo = getActiveSubAlgoConfig();
    const params = extractCurrentParams();

    showLoading('Executing GNU Octave', `Running ${subAlgo.name} (${activeSubAlgoId}.m)...`);

    try {
      const res = await fetch('/api/process', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          algorithm: activeSubAlgoId,
          imagePath: currentSelectedSource.path,
          params
        })
      });

      const data = await res.json();
      hideLoading();

      if (!data.success) {
        throw new Error(data.error || 'Octave algorithm failure');
      }

      // Display after image
      afterEmpty.style.display = 'none';
      afterImg.style.display = 'block';
      afterImg.src = data.relativeUrl;

      executionMetaText.textContent = `Executed in ${data.executionTimeMs} ms in GNU Octave.`;

      // Save to result object
      lastOutputResult = {
        id: `p3_${Date.now()}_${data.filename}`,
        method: activeMethodKey,
        algorithm: activeSubAlgoId,
        title: subAlgo.name,
        url: data.relativeUrl,
        path: data.outputPath,
        filename: data.filename,
        executionTimeMs: data.executionTimeMs,
        params,
        timestamp: new Date().toISOString()
      };

      window.sareeSession.addPage3Result(lastOutputResult);

      btnDownloadResult.disabled = false;
      btnSaveAsInput.disabled = false;

      // Re-populate source dropdown so the new result is immediately available
      populateSourceDropdown();
      renderP3Gallery();

      window.sareeSession.showToast(`${subAlgo.name} generated successfully!`, 'success');

    } catch (err) {
      hideLoading();
      window.sareeSession.showToast(`Error running algorithm: ${err.message}`, 'error');
    }
  });

  // --- Helpers ---

  function populateSourceDropdown(preselectId = null) {
    const list = window.sareeSession.getAllSelectableImages();
    sourceImageSelect.innerHTML = '';

    if (list.length === 0) {
      sourceImageSelect.innerHTML = '<option value="">No images available</option>';
      return;
    }

    let selectedFound = false;
    list.forEach(item => {
      const opt = document.createElement('option');
      opt.value = item.id;
      opt.textContent = `[${item.category}] ${item.title}`;
      if (preselectId && item.id === preselectId) {
        opt.selected = true;
        selectedFound = true;
      }
      sourceImageSelect.appendChild(opt);
    });

    if (!selectedFound && list.length > 0) {
      sourceImageSelect.selectedIndex = 0;
    }

    onSourceSelectionChanged();
  }

  function onSourceSelectionChanged() {
    const list = window.sareeSession.getAllSelectableImages();
    const selId = sourceImageSelect.value;
    currentSelectedSource = list.find(item => item.id === selId) || list[0] || null;

    if (currentSelectedSource && currentSelectedSource.url) {
      beforeImg.src = currentSelectedSource.url;
      sourceInfoText.textContent = `Active input: ${currentSelectedSource.title}`;
    }
  }

  function setupMethodCardSelection() {
    methodCards.forEach(card => {
      card.addEventListener('click', () => {
        methodCards.forEach(c => c.classList.remove('active'));
        card.classList.add('active');

        activeMethodKey = card.dataset.method;
        const config = METHODS_CONFIG[activeMethodKey];
        activeSubAlgoId = config.subAlgorithms[0].id;

        renderActiveMethodControls();
      });
    });
  }

  function renderActiveMethodControls() {
    const config = METHODS_CONFIG[activeMethodKey];
    activeMethodTitle.textContent = config.title;

    // Populate Sub-algorithms dropdown
    subAlgoSelect.innerHTML = '';
    config.subAlgorithms.forEach(sub => {
      const opt = document.createElement('option');
      opt.value = sub.id;
      opt.textContent = sub.name;
      subAlgoSelect.appendChild(opt);
    });

    subAlgoSelect.value = activeSubAlgoId;
    renderSubAlgoParams();
  }

  function getActiveSubAlgoConfig() {
    const config = METHODS_CONFIG[activeMethodKey];
    return config.subAlgorithms.find(s => s.id === activeSubAlgoId) || config.subAlgorithms[0];
  }

  function renderSubAlgoParams() {
    const sub = getActiveSubAlgoConfig();
    subAlgoMathDesc.textContent = sub.desc;
    dynamicParamsContainer.innerHTML = '';

    if (!sub.params || sub.params.length === 0) {
      return;
    }

    sub.params.forEach(p => {
      const group = document.createElement('div');
      group.className = 'form-group';

      if (p.type === 'select') {
        group.innerHTML = `
          <label class="form-label" for="p_${p.id}">${p.label}</label>
          <select class="form-select" id="p_${p.id}">
            ${p.options.map(opt => `<option value="${opt.val}" ${opt.val === p.default ? 'selected' : ''}>${opt.label}</option>`).join('')}
          </select>
        `;
      } else if (p.type === 'range') {
        group.innerHTML = `
          <label class="form-label" for="p_${p.id}">${p.label}: <span id="val_p_${p.id}">${p.default}</span></label>
          <input type="range" class="form-input" id="p_${p.id}" min="${p.min}" max="${p.max}" value="${p.default}" style="padding:0;">
        `;
        // Attach dynamic label update
        setTimeout(() => {
          const slider = group.querySelector(`#p_${p.id}`);
          const disp = group.querySelector(`#val_p_${p.id}`);
          if (slider && disp) {
            slider.addEventListener('input', () => { disp.textContent = slider.value; });
          }
        }, 10);
      } else if (p.type === 'number') {
        group.innerHTML = `
          <label class="form-label" for="p_${p.id}">${p.label}</label>
          <input type="number" class="form-input" id="p_${p.id}" value="${p.default}" min="${p.min || 0}" max="${p.max || 100}" step="${p.step || 1}">
        `;
      }

      dynamicParamsContainer.appendChild(group);
    });
  }

  function extractCurrentParams() {
    const sub = getActiveSubAlgoConfig();
    const params = {};

    if (!sub.params) return params;

    sub.params.forEach(p => {
      const inputEl = document.getElementById(`p_${p.id}`);
      if (inputEl) {
        if (p.id === 'targetPreset') {
          const presets = {
            gold: [218, 165, 32],
            ruby: [155, 17, 30],
            emerald: [9, 121, 105],
            sapphire: [20, 24, 82]
          };
          params.targetColor = presets[inputEl.value] || [218, 165, 32];
        } else if (p.type === 'number' || p.type === 'range') {
          params[p.id] = parseFloat(inputEl.value);
        } else {
          params[p.id] = inputEl.value;
        }
      }
    });

    return params;
  }

  function renderP3Gallery() {
    const results = window.sareeSession.getPage3Results();
    if (results.length === 0) return;

    p3ResultsGallery.innerHTML = '';
    results.forEach(res => {
      const card = document.createElement('div');
      card.className = 'result-card';
      card.innerHTML = `
        <div class="result-thumb-wrap">
          <img src="${res.url}" alt="${res.title}" loading="lazy">
        </div>
        <div class="result-meta">
          <div>
            <div class="result-title">${res.title}</div>
            <div class="result-param">Engine: GNU Octave &bull; ${res.executionTimeMs ? `${res.executionTimeMs} ms` : 'Ready'}</div>
          </div>
          <div class="result-actions">
            <a href="/api/download/${res.filename}" class="btn btn-outline-sm" style="flex:1;">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              Download
            </a>
          </div>
        </div>
      `;
      p3ResultsGallery.appendChild(card);
    });

    p3GallerySubtitle.textContent = `${results.length} intermediate result(s) available for export or motif extraction.`;
  }

  function restoreP3Gallery() {
    const results = window.sareeSession.getPage3Results();
    if (results && results.length > 0) {
      renderP3Gallery();
    }
  }

  function showLoading(title, desc) {
    loadingTitle.textContent = title;
    loadingDesc.textContent = desc;
    loadingOverlay.classList.add('visible');
  }

  function hideLoading() {
    loadingOverlay.classList.remove('visible');
  }
});
