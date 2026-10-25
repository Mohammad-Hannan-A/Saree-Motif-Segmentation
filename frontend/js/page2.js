/**
 * page2.js - Logic for Page 2: Six Basic Image-Processing Algorithms
 * Communicates with GNU Octave backend via /api/process-batch.
 */

document.addEventListener('DOMContentLoaded', () => {
  // Navigation guard
  const check = window.sareeSession.canNavigateTo(2);
  if (!check.allowed) {
    alert(check.reason);
    window.location.href = 'page1.html';
    return;
  }

  // Initialize Header Navigation for Step 2
  window.sareeSession.initHeader(2);

  // UI Elements
  const sourceRadios = document.querySelectorAll('input[name="sourceChoice"]');
  const sourcePreviewImg = document.getElementById('source-preview-img');
  const sourceSubtitle = document.getElementById('source-subtitle');
  const sourceBadge = document.getElementById('source-badge');
  const btnSelectAll = document.getElementById('btn-select-all');
  const btnDeselectAll = document.getElementById('btn-deselect-all');
  const btnApply = document.getElementById('btn-apply-algos');
  const btnBackPage1 = document.getElementById('btn-back-page1');
  const btnSaveContinueP3 = document.getElementById('btn-save-continue-p3');
  const btnContinueGallery = document.getElementById('btn-continue-gallery');
  const resultsGallery = document.getElementById('results-gallery');
  const galleryStatus = document.getElementById('gallery-status');
  const loadingOverlay = document.getElementById('loading-overlay');
  const loadingTitle = document.getElementById('loading-title');
  const loadingDesc = document.getElementById('loading-desc');

  // Algorithm checkboxes
  const algoItems = document.querySelectorAll('.algo-check-item');
  const chkResizing = document.getElementById('chk-resizing');
  const chkThresholding = document.getElementById('chk-thresholding');
  const chkGaussian = document.getElementById('chk-gaussian');
  const pThreshMode = document.getElementById('p-thresh-mode');
  const pThreshSliderBox = document.getElementById('p-thresh-slider-box');
  const pThreshVal = document.getElementById('p-thresh-val');
  const threshValDisplay = document.getElementById('thresh-val-display');

  // Load and display current source image
  updateSourceImageDisplay();

  // Restore previously generated results from session
  restoreGalleryFromSession();

  // Radio button source switcher
  sourceRadios.forEach(radio => {
    radio.addEventListener('change', () => {
      updateSourceImageDisplay();
    });
  });

  // Algorithm checkbox toggle styling
  algoItems.forEach(item => {
    const chk = item.querySelector('input[type="checkbox"]');
    chk.addEventListener('change', () => {
      if (chk.checked) {
        item.classList.add('selected');
      } else {
        item.classList.remove('selected');
      }
    });
  });

  // Threshold controls
  pThreshMode.addEventListener('change', () => {
    if (pThreshMode.value === 'manual') {
      pThreshSliderBox.style.display = 'block';
    } else {
      pThreshSliderBox.style.display = 'none';
    }
  });

  pThreshVal.addEventListener('input', () => {
    threshValDisplay.textContent = pThreshVal.value;
  });

  // Select All / Deselect All
  btnSelectAll.addEventListener('click', () => {
    algoItems.forEach(item => {
      const chk = item.querySelector('input[type="checkbox"]');
      chk.checked = true;
      item.classList.add('selected');
    });
  });

  btnDeselectAll.addEventListener('click', () => {
    algoItems.forEach(item => {
      const chk = item.querySelector('input[type="checkbox"]');
      chk.checked = false;
      item.classList.remove('selected');
    });
  });

  // Navigation Buttons
  btnBackPage1.addEventListener('click', () => {
    window.location.href = 'page1.html';
  });

  function onContinueToPage3() {
    window.sareeSession.showToast('Page 2 results verified! Continuing to Page 3.', 'success');
    setTimeout(() => {
      window.location.href = 'page3.html';
    }, 400);
  }

  btnSaveContinueP3.addEventListener('click', onContinueToPage3);
  btnContinueGallery.addEventListener('click', onContinueToPage3);

  // Apply Selected Algorithms click
  btnApply.addEventListener('click', async () => {
    const selectedRequests = gatherSelectedAlgorithms();
    if (selectedRequests.length === 0) {
      window.sareeSession.showToast('Please check at least one algorithm to run.', 'warning');
      return;
    }

    const currentSource = getActiveSourceImage();
    if (!currentSource || !currentSource.path) {
      window.sareeSession.showToast('No valid source image available.', 'error');
      return;
    }

    showLoading('Executing GNU Octave', `Preparing batch request for ${selectedRequests.length} algorithm(s)...`);

    try {
      const res = await fetch('/api/process-batch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          imagePath: currentSource.path,
          algorithms: selectedRequests
        })
      });

      const data = await res.json();
      hideLoading();

      if (!data.success) {
        throw new Error(data.error || 'Batch processing failed');
      }

      // Process results
      let successCount = 0;
      data.results.forEach(item => {
        if (item.success) {
          successCount++;
          const title = getReadableAlgoTitle(item.algorithm);
          const resultObj = {
            id: `p2_${Date.now()}_${item.filename}`,
            algorithm: item.algorithm,
            title,
            url: item.relativeUrl,
            path: item.outputPath,
            filename: item.filename,
            executionTimeMs: item.executionTimeMs,
            sourceType: currentSource.type,
            timestamp: new Date().toISOString()
          };
          window.sareeSession.addPage2Result(resultObj);
        } else {
          window.sareeSession.showToast(`Error in ${item.algorithm}: ${item.error}`, 'error');
        }
      });

      renderGallery();
      btnSaveContinueP3.disabled = false;
      btnContinueGallery.disabled = false;
      galleryStatus.textContent = `Generated ${successCount} output(s) successfully in GNU Octave.`;
      window.sareeSession.showToast(`Generated ${successCount} image outputs successfully!`, 'success');

    } catch (err) {
      hideLoading();
      window.sareeSession.showToast(`Batch execution failed: ${err.message}`, 'error');
    }
  });

  // --- Helpers ---

  function updateSourceImageDisplay() {
    const source = getActiveSourceImage();
    if (source && source.url) {
      sourcePreviewImg.src = source.url;
      sourceSubtitle.textContent = source.label;
      sourceBadge.textContent = source.type === 'original' ? 'RGB Saree' : 'Grayscale';
    }
  }

  function getActiveSourceImage() {
    const choice = document.querySelector('input[name="sourceChoice"]:checked').value;
    if (choice === 'grayscale') {
      const gray = window.sareeSession.getGrayscaleImage();
      if (gray && gray.url) {
        return { ...gray, label: 'Using Page 1 Grayscale Image', type: 'grayscale' };
      }
    }
    const orig = window.sareeSession.getOriginalImage();
    return { ...orig, label: 'Using Original Color Saree (RGB)', type: 'original' };
  }

  function gatherSelectedAlgorithms() {
    const list = [];

    // 1. Grayscale
    if (document.getElementById('chk-grayscale').checked) {
      list.push({ algorithm: 'grayscale_conversion', params: {} });
    }

    // 2. Negative
    if (document.getElementById('chk-negative').checked) {
      list.push({ algorithm: 'image_negative', params: {} });
    }

    // 3. Resizing
    if (chkResizing.checked) {
      const w = parseInt(document.getElementById('p-resize-w').value, 10) || 300;
      const h = parseInt(document.getElementById('p-resize-h').value, 10) || 300;
      const preserve = document.getElementById('p-resize-aspect').checked;
      list.push({
        algorithm: 'image_resizing',
        params: { targetWidth: w, targetHeight: h, preserveAspect: preserve }
      });
    }

    // 4. Thresholding
    if (chkThresholding.checked) {
      const mode = pThreshMode.value;
      const val = mode === 'manual' ? parseInt(pThreshVal.value, 10) : -1;
      const inv = document.getElementById('p-thresh-invert').checked;
      list.push({
        algorithm: 'image_thresholding',
        params: { threshold: val, invert: inv }
      });
    }

    // 5. Gaussian
    if (chkGaussian.checked) {
      const kSize = parseInt(document.getElementById('p-gauss-ksize').value, 10) || 5;
      const sigma = parseFloat(document.getElementById('p-gauss-sigma').value) || 1.5;
      list.push({
        algorithm: 'gaussian_filtering',
        params: { kernelSize: kSize, sigma }
      });
    }

    // 6. RGB to HSV
    if (document.getElementById('chk-hsv').checked) {
      list.push({ algorithm: 'rgb_to_hsv_conversion', params: {} });
    }

    return list;
  }

  function getReadableAlgoTitle(algo) {
    const titles = {
      grayscale: 'Grayscale Conversion',
      grayscale_conversion: 'Grayscale Conversion',
      imageNegative: 'Image Negative',
      image_negative: 'Image Negative',
      imageResizing: 'Image Resizing',
      image_resizing: 'Image Resizing',
      binaryThreshold: 'Image Thresholding',
      imageThresholding: 'Image Thresholding',
      image_thresholding: 'Image Thresholding',
      gaussianFilter: 'Gaussian Filtering',
      gaussianFiltering: 'Gaussian Filtering',
      gaussian_filtering: 'Gaussian Filtering',
      rgbToHsvConversion: 'RGB to HSV Color Conversion',
      rgb_to_hsv_conversion: 'RGB to HSV Color Conversion'
    };
    return titles[algo] || algo;
  }

  function renderGallery() {
    const results = window.sareeSession.getPage2Results();
    if (results.length === 0) return;

    resultsGallery.innerHTML = '';
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
      resultsGallery.appendChild(card);
    });
  }

  function restoreGalleryFromSession() {
    const results = window.sareeSession.getPage2Results();
    if (results && results.length > 0) {
      renderGallery();
      btnSaveContinueP3.disabled = false;
      btnContinueGallery.disabled = false;
      galleryStatus.textContent = `${results.length} saved output(s) restored from session.`;
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
