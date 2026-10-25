/**
 * page4.js - Logic for Page 4: Motif Extraction & Application
 * Communicates with GNU Octave backend via /api/crop-bbox, /api/extract-motif, and /api/compose.
 */

// Global Tab Switcher
function switchMainTab(tab) {
  const tabExtract = document.getElementById('tab-extract');
  const tabCompose = document.getElementById('tab-compose');
  const secExtract = document.getElementById('section-extract');
  const secCompose = document.getElementById('section-compose');

  if (tab === 'compose') {
    tabExtract.classList.remove('active');
    tabCompose.classList.add('active');
    secExtract.style.display = 'none';
    secCompose.style.display = 'block';
  } else {
    tabCompose.classList.remove('active');
    tabExtract.classList.add('active');
    secCompose.style.display = 'none';
    secExtract.style.display = 'block';
  }
}

document.addEventListener('DOMContentLoaded', () => {
  // Initialize Header Navigation for Step 4
  window.sareeSession.initHeader(4);

  // --- UI Elements for Extraction ---
  const motifSourceSelect = document.getElementById('motif-source-select');
  const extraSourceUpload = document.getElementById('extra-source-upload');
  const extractMethodSelect = document.getElementById('extract-method-select');
  const panelBboxControls = document.getElementById('panel-bbox-controls');
  const panelMaskOptions = document.getElementById('panel-mask-options');
  const extractColorTol = document.getElementById('extract-color-tol');
  const dispColorTol = document.getElementById('disp-color-tol');
  const btnRunExtraction = document.getElementById('btn-run-extraction');
  const extractSourceImg = document.getElementById('extract-source-img');
  const cropContainer = document.getElementById('crop-container');
  const cropBoxRect = document.getElementById('crop-box-rect');
  const motifResultImg = document.getElementById('motif-result-img');
  const motifEmpty = document.getElementById('motif-empty');
  const motifTypeBadge = document.getElementById('motif-type-badge');
  const btnDownloadMotif = document.getElementById('btn-download-motif');
  const btnUseForComposite = document.getElementById('btn-use-for-composite');
  const btnBackPage3 = document.getElementById('btn-back-page3');
  const boxX = document.getElementById('box-x');
  const boxY = document.getElementById('box-y');
  const boxW = document.getElementById('box-w');
  const boxH = document.getElementById('box-h');

  // --- UI Elements for Compositing ---
  const destImageSelect = document.getElementById('dest-image-select');
  const destUploadInput = document.getElementById('dest-upload-input');
  const composeX = document.getElementById('compose-x');
  const composeY = document.getElementById('compose-y');
  const composeScale = document.getElementById('compose-scale');
  const composeAngle = document.getElementById('compose-angle');
  const composeOpacity = document.getElementById('compose-opacity');
  const dispPosX = document.getElementById('disp-pos-x');
  const dispPosY = document.getElementById('disp-pos-y');
  const dispScale = document.getElementById('disp-scale');
  const dispAngle = document.getElementById('disp-angle');
  const dispOpacity = document.getElementById('disp-opacity');
  const btnRunCompose = document.getElementById('btn-run-compose');
  const composeResultImg = document.getElementById('compose-result-img');
  const composeEmpty = document.getElementById('compose-empty');
  const btnDownloadComposite = document.getElementById('btn-download-composite');
  const composeStatusText = document.getElementById('compose-status-text');

  const loadingOverlay = document.getElementById('loading-overlay');
  const loadingTitle = document.getElementById('loading-title');
  const loadingDesc = document.getElementById('loading-desc');

  // State
  let currentSourceItem = null;
  let activeExtractedResult = null;
  let activeCompositeResult = null;
  let sampleDestinations = [];
  let currentDestPath = null;

  // Initialize
  populateSourceDropdown();
  loadDestinations();
  setupBoundingBoxDrawing();

  // Color tolerance slider display
  extractColorTol.addEventListener('input', () => {
    dispColorTol.textContent = extractColorTol.value;
  });

  // Slider value displays for compositing
  composeX.addEventListener('input', () => { dispPosX.textContent = composeX.value; });
  composeY.addEventListener('input', () => { dispPosY.textContent = composeY.value; });
  composeScale.addEventListener('input', () => { dispScale.textContent = composeScale.value; });
  composeAngle.addEventListener('input', () => { dispAngle.textContent = composeAngle.value; });
  composeOpacity.addEventListener('input', () => { dispOpacity.textContent = composeOpacity.value; });

  // Navigation
  btnBackPage3.addEventListener('click', () => {
    window.location.href = 'page3.html';
  });

  // Source selection change
  motifSourceSelect.addEventListener('change', () => {
    onSourceSelectionChanged();
  });

  // Extra image upload for extraction
  extraSourceUpload.addEventListener('change', async () => {
    if (extraSourceUpload.files && extraSourceUpload.files[0]) {
      const file = extraSourceUpload.files[0];
      const formData = new FormData();
      formData.append('image', file);

      showLoading('Uploading Image', 'Storing custom image on backend...');
      try {
        const res = await fetch('/api/upload', { method: 'POST', body: formData });
        const data = await res.json();
        hideLoading();

        if (data.success) {
          const item = {
            id: `custom_${Date.now()}`,
            title: `Custom Upload: ${data.file.originalName}`,
            category: 'Custom Upload',
            url: data.file.url,
            path: data.file.path,
            filename: data.file.filename
          };
          window.sareeSession.setOriginalImage(item);
          populateSourceDropdown(item.id);
          window.sareeSession.showToast('Loaded custom image for motif extraction!', 'success');
        }
      } catch (e) {
        hideLoading();
        window.sareeSession.showToast(`Upload failed: ${e.message}`, 'error');
      }
    }
  });

  // Method change toggle
  extractMethodSelect.addEventListener('change', () => {
    const val = extractMethodSelect.value;
    if (val === 'bbox') {
      panelBboxControls.style.display = 'block';
      panelMaskOptions.style.display = 'none';
      cropBoxRect.style.display = 'block';
      motifTypeBadge.textContent = 'Crop Only';
    } else {
      panelBboxControls.style.display = 'none';
      panelMaskOptions.style.display = 'block';
      cropBoxRect.style.display = 'none';
      motifTypeBadge.textContent = 'Transparent PNG';
    }
  });

  // Run Extraction Click
  btnRunExtraction.addEventListener('click', async () => {
    if (!currentSourceItem || !currentSourceItem.path) {
      window.sareeSession.showToast('Please select a valid source image.', 'error');
      return;
    }

    const mode = extractMethodSelect.value;

    if (mode === 'bbox') {
      // 1. Exact Bounding Box Cropping in Octave
      const x = parseInt(boxX.value, 10) || 1;
      const y = parseInt(boxY.value, 10) || 1;
      const w = parseInt(boxW.value, 10) || 100;
      const h = parseInt(boxH.value, 10) || 100;

      showLoading('Executing GNU Octave', 'Cropping Region of Interest in bounding_box_crop.m...');

      try {
        const res = await fetch('/api/crop-bbox', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            imagePath: currentSourceItem.path,
            bbox: [x, y, w, h]
          })
        });

        const data = await res.json();
        hideLoading();

        if (!data.success) {
          throw new Error(data.error || 'Octave crop failed');
        }

        activeExtractedResult = {
          type: 'crop',
          url: data.croppedUrl,
          path: data.croppedPath,
          filename: data.filename,
          width: w,
          height: h
        };

        displayExtractedResult(data.croppedUrl, 'Bounding Box Cropped Region Only');
        btnDownloadMotif.disabled = false;
        btnUseForComposite.disabled = false;
        window.sareeSession.showToast('Cropped bounding box strictly in GNU Octave!', 'success');

      } catch (err) {
        hideLoading();
        window.sareeSession.showToast(`Crop failed: ${err.message}`, 'error');
      }

    } else {
      // 2. Mask-Based Transparent PNG Extraction
      showLoading('Executing GNU Octave', 'Generating segmentation mask & refining with morphology...');

      try {
        // Step A: Segment
        const colorPreset = document.getElementById('extract-color-preset').value;
        const presets = {
          gold: [218, 165, 32],
          ruby: [155, 17, 30],
          emerald: [9, 121, 105],
          sapphire: [20, 24, 82]
        };
        const targetColor = presets[colorPreset] || [218, 165, 32];
        const tolerance = parseInt(extractColorTol.value, 10) || 60;

        const segRes = await fetch('/api/segment', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            imagePath: currentSourceItem.path,
            method: mode === 'color' ? 'color' : 'otsu',
            params: { targetColor, tolerance }
          })
        });
        const segData = await segRes.json();
        if (!segData.success) throw new Error(segData.error || 'Segmentation failed');

        // Step B: Refine mask with morphology
        const fillHoles = document.getElementById('mask-fill-holes').checked;
        const cleanNoise = document.getElementById('mask-clean-noise').checked;
        const ops = [];
        if (cleanNoise) ops.push('remove_noise');
        if (fillHoles) ops.push('fill_holes');
        ops.push('smooth');

        const refineRes = await fetch('/api/refine-mask', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            maskPath: segData.maskPath,
            operations: ops
          })
        });
        const refineData = await refineRes.json();
        if (!refineData.success) throw new Error(refineData.error || 'Mask refinement failed');

        // Step C: Extract transparent 32-bit RGBA PNG
        const extractRes = await fetch('/api/extract-motif', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            sourceImagePath: currentSourceItem.path,
            maskPath: refineData.refinedMaskPath,
            padding: 5
          })
        });
        const extractData = await extractRes.json();
        hideLoading();

        if (!extractData.success) throw new Error(extractData.error || 'Transparent PNG extraction failed');

        activeExtractedResult = {
          type: 'transparent_png',
          url: extractData.transparentPngUrl,
          path: extractData.transparentPngPath,
          filename: extractData.filename,
          maskPath: refineData.refinedMaskPath
        };

        displayExtractedResult(extractData.transparentPngUrl, '32-Bit Transparent PNG Motif (Alpha Matte)');
        btnDownloadMotif.disabled = false;
        btnUseForComposite.disabled = false;

        window.sareeSession.showToast('Extracted genuine transparent motif PNG via GNU Octave!', 'success');

      } catch (err) {
        hideLoading();
        window.sareeSession.showToast(`Extraction error: ${err.message}`, 'error');
      }
    }
  });

  // Download Extracted Motif
  btnDownloadMotif.addEventListener('click', () => {
    if (activeExtractedResult && activeExtractedResult.filename) {
      window.location.href = `/api/download/${activeExtractedResult.filename}`;
    }
  });

  // Use for Compositing
  btnUseForComposite.addEventListener('click', () => {
    if (!activeExtractedResult) return;
    switchMainTab('compose');
    window.sareeSession.showToast('Motif loaded into Compositing tab! Adjust placement and click Composite.', 'info');
  });

  // Run Compositing
  btnRunCompose.addEventListener('click', async () => {
    if (!activeExtractedResult || !activeExtractedResult.path) {
      window.sareeSession.showToast('Please extract or crop a motif in Section A first.', 'warning');
      switchMainTab('extract');
      return;
    }

    if (!currentDestPath) {
      window.sareeSession.showToast('No destination garment selected.', 'error');
      return;
    }

    const posX = parseInt(composeX.value, 10) || 50;
    const posY = parseInt(composeY.value, 10) || 50;
    const scale = parseFloat(composeScale.value) || 1.0;
    const angle = parseFloat(composeAngle.value) || 0;
    const opacity = parseFloat(composeOpacity.value) || 1.0;

    showLoading('Executing GNU Octave', 'Blending motif onto destination via Porter-Duff Alpha Over operator...');

    try {
      const res = await fetch('/api/compose', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          destImagePath: currentDestPath,
          motifPath: activeExtractedResult.path,
          maskPath: activeExtractedResult.maskPath || null,
          posX,
          posY,
          scale,
          angle,
          opacity
        })
      });

      const data = await res.json();
      hideLoading();

      if (!data.success) {
        throw new Error(data.error || 'Octave composition failed');
      }

      activeCompositeResult = {
        url: data.compositeUrl,
        path: data.compositePath,
        filename: data.filename,
        executionTimeMs: data.executionTimeMs
      };

      composeEmpty.style.display = 'none';
      composeResultImg.style.display = 'block';
      composeResultImg.src = data.compositeUrl;

      btnDownloadComposite.disabled = false;
      composeStatusText.textContent = `Porter-Duff Alpha blended in ${data.executionTimeMs} ms in GNU Octave.`;

      window.sareeSession.showToast('Motif successfully composited onto destination garment!', 'success');

    } catch (err) {
      hideLoading();
      window.sareeSession.showToast(`Compositing error: ${err.message}`, 'error');
    }
  });

  // Download Composited Image
  btnDownloadComposite.addEventListener('click', () => {
    if (activeCompositeResult && activeCompositeResult.filename) {
      window.location.href = `/api/download/${activeCompositeResult.filename}`;
    }
  });

  // Destination upload
  destUploadInput.addEventListener('change', async () => {
    if (destUploadInput.files && destUploadInput.files[0]) {
      const file = destUploadInput.files[0];
      const formData = new FormData();
      formData.append('image', file);

      showLoading('Uploading Destination Image', 'Saving garment/photo to backend...');
      try {
        const res = await fetch('/api/upload', { method: 'POST', body: formData });
        const data = await res.json();
        hideLoading();

        if (data.success) {
          currentDestPath = data.file.path;
          const opt = document.createElement('option');
          opt.value = data.file.path;
          opt.textContent = `Custom Upload: ${data.file.originalName}`;
          opt.selected = true;
          destImageSelect.appendChild(opt);
          window.sareeSession.showToast('Custom destination image loaded!', 'success');
        }
      } catch (e) {
        hideLoading();
        window.sareeSession.showToast(`Upload failed: ${e.message}`, 'error');
      }
    }
  });

  destImageSelect.addEventListener('change', () => {
    currentDestPath = destImageSelect.value;
  });

  // --- Helper Functions ---

  function populateSourceDropdown(preselectId = null) {
    const list = window.sareeSession.getAllSelectableImages();
    motifSourceSelect.innerHTML = '';

    if (list.length === 0) {
      motifSourceSelect.innerHTML = '<option value="">No images available</option>';
      return;
    }

    list.forEach(item => {
      const opt = document.createElement('option');
      opt.value = item.id;
      opt.textContent = `[${item.category}] ${item.title}`;
      if (preselectId && item.id === preselectId) {
        opt.selected = true;
      }
      motifSourceSelect.appendChild(opt);
    });

    onSourceSelectionChanged();
  }

  function onSourceSelectionChanged() {
    const list = window.sareeSession.getAllSelectableImages();
    const selId = motifSourceSelect.value;
    currentSourceItem = list.find(item => item.id === selId) || list[0] || null;

    if (currentSourceItem && currentSourceItem.url) {
      extractSourceImg.src = currentSourceItem.url;
      extractSourceImg.onload = () => {
        // Reset bounding box to center 50%
        const nw = extractSourceImg.naturalWidth || 400;
        const nh = extractSourceImg.naturalHeight || 400;
        boxX.value = Math.round(nw * 0.25);
        boxY.value = Math.round(nh * 0.25);
        boxW.value = Math.round(nw * 0.5);
        boxH.value = Math.round(nh * 0.5);
        updateCropBoxOverlay();
      };
    }
  }

  async function loadDestinations() {
    try {
      const res = await fetch('/api/samples');
      const data = await res.json();
      if (data.success && data.samples) {
        const dests = data.samples.filter(s => s.type === 'destination');
        sampleDestinations = dests;
        destImageSelect.innerHTML = '';
        dests.forEach((d, idx) => {
          const opt = document.createElement('option');
          opt.value = d.path;
          opt.textContent = `${d.title} (Pre-packaged Sample)`;
          if (idx === 0) {
            opt.selected = true;
            currentDestPath = d.path;
          }
          destImageSelect.appendChild(opt);
        });
      }
    } catch (e) {
      console.warn('Could not load destinations:', e);
    }
  }

  function setupBoundingBoxDrawing() {
    let isDrawing = false;
    let startX = 0, startY = 0;

    cropContainer.addEventListener('mousedown', (e) => {
      if (extractMethodSelect.value !== 'bbox') return;
      isDrawing = true;
      const rect = extractSourceImg.getBoundingClientRect();
      startX = e.clientX - rect.left;
      startY = e.clientY - rect.top;
      cropBoxRect.style.display = 'block';
      updateCropRectVisual(startX, startY, 1, 1);
    });

    window.addEventListener('mousemove', (e) => {
      if (!isDrawing) return;
      const rect = extractSourceImg.getBoundingClientRect();
      const currentX = Math.max(0, Math.min(rect.width, e.clientX - rect.left));
      const currentY = Math.max(0, Math.min(rect.height, e.clientY - rect.top));

      const left = Math.min(startX, currentX);
      const top = Math.min(startY, currentY);
      const width = Math.abs(currentX - startX);
      const height = Math.abs(currentY - startY);

      updateCropRectVisual(left, top, width, height);

      // Convert displayed client coords to real natural pixel coords
      const scaleX = extractSourceImg.naturalWidth / rect.width;
      const scaleY = extractSourceImg.naturalHeight / rect.height;

      boxX.value = Math.round(left * scaleX);
      boxY.value = Math.round(top * scaleY);
      boxW.value = Math.max(5, Math.round(width * scaleX));
      boxH.value = Math.max(5, Math.round(height * scaleY));
    });

    window.addEventListener('mouseup', () => {
      if (isDrawing) {
        isDrawing = false;
      }
    });

    // Inputs change updates overlay
    [boxX, boxY, boxW, boxH].forEach(input => {
      input.addEventListener('input', () => {
        updateCropBoxOverlay();
      });
    });
  }

  function updateCropRectVisual(left, top, width, height) {
    cropBoxRect.style.left = `${left}px`;
    cropBoxRect.style.top = `${top}px`;
    cropBoxRect.style.width = `${width}px`;
    cropBoxRect.style.height = `${height}px`;
  }

  function updateCropBoxOverlay() {
    if (extractMethodSelect.value !== 'bbox') return;
    const rect = extractSourceImg.getBoundingClientRect();
    if (!rect.width || !extractSourceImg.naturalWidth) return;

    const scaleX = rect.width / extractSourceImg.naturalWidth;
    const scaleY = rect.height / extractSourceImg.naturalHeight;

    const left = parseInt(boxX.value, 10) * scaleX;
    const top = parseInt(boxY.value, 10) * scaleY;
    const width = parseInt(boxW.value, 10) * scaleX;
    const height = parseInt(boxH.value, 10) * scaleY;

    cropBoxRect.style.display = 'block';
    updateCropRectVisual(left, top, width, height);
  }

  function displayExtractedResult(url, title) {
    motifEmpty.style.display = 'none';
    motifResultImg.style.display = 'block';
    motifResultImg.src = url;
    document.getElementById('extracted-pane-title').textContent = title;
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
