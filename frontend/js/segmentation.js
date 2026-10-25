/**
 * segmentation.js - Interactive Saree Motif Segmentation Controller
 * Saree Motif Segmentation Project
 */

let currentSourceImage = null; // { path, url, name, naturalWidth, naturalHeight }
let currentMask = null; // { path, url }
let currentTransparentMotif = null; // { path, url, bbox, dimensions }

// Canvas ROI selection state
let canvas, ctx;
let isDragging = false;
let startX = 0, startY = 0;
let currentRoi = null; // [x, y, w, h] in canvas display coordinates
let imgElement = new Image();

document.addEventListener('DOMContentLoaded', async () => {
  initCanvas();
  initSampleSelector();
  initMethodSelector();
  initActions();

  // Check if an image was passed from the Home / Processing page
  const saved = sessionStorage.getItem('currentSareeImage');
  if (saved) {
    try {
      const parsed = JSON.parse(saved);
      loadSourceImage(parsed);
    } catch (e) {}
  }
});

// Canvas Setup
function initCanvas() {
  canvas = document.getElementById('roiCanvas');
  if (!canvas) return;
  ctx = canvas.getContext('2d');

  canvas.addEventListener('mousedown', onMouseDown);
  canvas.addEventListener('mousemove', onMouseMove);
  canvas.addEventListener('mouseup', onMouseUp);
  canvas.addEventListener('mouseleave', onMouseUp);

  // File Upload
  const fileInput = document.getElementById('segFileInput');
  if (fileInput) {
    fileInput.onchange = async (e) => {
      if (e.target.files && e.target.files[0]) {
        try {
          showToast(`Uploading ${e.target.files[0].name}...`, 'info');
          const uploaded = await uploadImageFile(e.target.files[0]);
          loadSourceImage({
            path: uploaded.path,
            url: uploaded.url,
            name: uploaded.originalName
          });
          showToast('Image loaded successfully!', 'success');
        } catch (err) {
          showToast(err.message, 'error');
        }
      }
    };
  }
}

async function initSampleSelector() {
  const container = document.getElementById('segSampleChips');
  if (!container) return;

  const samples = await loadSampleImages('saree');
  container.innerHTML = '';

  samples.forEach((sample, idx) => {
    const chip = document.createElement('div');
    chip.className = 'sample-chip';
    chip.innerHTML = `
      <img src="${sample.url}" class="sample-thumb" alt="${sample.title}">
      <span>${sample.title}</span>
    `;
    chip.onclick = () => {
      loadSourceImage({
        path: sample.path,
        url: sample.url,
        name: sample.title
      });
      showToast(`Loaded ${sample.title}`, 'info');
    };
    container.appendChild(chip);

    // If no image loaded yet, auto-select first sample
    if (idx === 0 && !currentSourceImage) {
      loadSourceImage({
        path: sample.path,
        url: sample.url,
        name: sample.title
      });
    }
  });
}

function loadSourceImage(imgInfo) {
  currentSourceImage = imgInfo;
  currentMask = null;
  currentTransparentMotif = null;

  imgElement = new Image();
  imgElement.onload = () => {
    currentSourceImage.naturalWidth = imgElement.naturalWidth;
    currentSourceImage.naturalHeight = imgElement.naturalHeight;

    // Size canvas maintaining aspect ratio
    const maxWidth = 550;
    const maxHeight = 500;
    let w = imgElement.naturalWidth;
    let h = imgElement.naturalHeight;

    if (w > maxWidth) {
      h = Math.round(h * (maxWidth / w));
      w = maxWidth;
    }
    if (h > maxHeight) {
      w = Math.round(w * (maxHeight / h));
      h = maxHeight;
    }

    canvas.width = w;
    canvas.height = h;

    // Reset ROI
    currentRoi = null;
    drawCanvas();
    updateRoiInputs(0, 0, currentSourceImage.naturalWidth, currentSourceImage.naturalHeight);

    const stats = document.getElementById('segImageStats');
    if (stats) {
      stats.innerHTML = `<span>Res: <strong>${imgElement.naturalWidth}x${imgElement.naturalHeight}</strong></span> <span>Source: <strong>${imgInfo.name}</strong></span>`;
    }
  };
  imgElement.src = imgInfo.url;
}

function drawCanvas() {
  if (!ctx || !imgElement.complete) return;

  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(imgElement, 0, 0, canvas.width, canvas.height);

  if (currentRoi && currentRoi[2] > 0 && currentRoi[3] > 0) {
    const [rx, ry, rw, rh] = currentRoi;

    // Darken exterior
    ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
    ctx.fillRect(0, 0, canvas.width, ry);
    ctx.fillRect(0, ry, rx, rh);
    ctx.fillRect(rx + rw, ry, canvas.width - (rx + rw), rh);
    ctx.fillRect(0, ry + rh, canvas.width, canvas.height - (ry + rh));

    // Golden dashed bounding box
    ctx.strokeStyle = '#d4af37';
    ctx.lineWidth = 2;
    ctx.setLineDash([6, 4]);
    ctx.strokeRect(rx, ry, rw, rh);
    ctx.setLineDash([]);

    // Corner handles
    ctx.fillStyle = '#ffffff';
    const hSize = 6;
    ctx.fillRect(rx - hSize/2, ry - hSize/2, hSize, hSize);
    ctx.fillRect(rx + rw - hSize/2, ry - hSize/2, hSize, hSize);
    ctx.fillRect(rx - hSize/2, ry + rh - hSize/2, hSize, hSize);
    ctx.fillRect(rx + rw - hSize/2, ry + rh - hSize/2, hSize, hSize);

    // Dimension label tag
    ctx.fillStyle = '#d4af37';
    ctx.fillRect(rx, ry - 22, 90, 20);
    ctx.fillStyle = '#0a0d14';
    ctx.font = 'bold 11px Inter, sans-serif';
    const [origX, origY, origW, origH] = getOriginalImageRoi();
    ctx.fillText(`${origW} x ${origH} px`, rx + 6, ry - 7);
  }
}

function onMouseDown(e) {
  const rect = canvas.getBoundingClientRect();
  startX = e.clientX - rect.left;
  startY = e.clientY - rect.top;
  isDragging = true;
  currentRoi = [startX, startY, 0, 0];
}

function onMouseMove(e) {
  if (!isDragging) return;
  const rect = canvas.getBoundingClientRect();
  const currentX = Math.max(0, minVal(canvas.width, e.clientX - rect.left));
  const currentY = Math.max(0, minVal(canvas.height, e.clientY - rect.top));

  const rx = Math.min(startX, currentX);
  const ry = Math.min(startY, currentY);
  const rw = Math.abs(currentX - startX);
  const rh = Math.abs(currentY - startY);

  currentRoi = [rx, ry, rw, rh];
  drawCanvas();

  const [origX, origY, origW, origH] = getOriginalImageRoi();
  updateRoiInputs(origX, origY, origW, origH);
}

function onMouseUp() {
  if (isDragging) {
    isDragging = false;
    if (currentRoi && (currentRoi[2] < 5 || currentRoi[3] < 5)) {
      currentRoi = null;
      drawCanvas();
      updateRoiInputs(1, 1, currentSourceImage.naturalWidth, currentSourceImage.naturalHeight);
    }
  }
}

function minVal(a, b) {
  return a < b ? a : b;
}

// Converts canvas display coordinates to original image coordinates
function getOriginalImageRoi() {
  if (!currentRoi || !currentSourceImage || !canvas.width) {
    if (currentSourceImage) {
      return [1, 1, currentSourceImage.naturalWidth, currentSourceImage.naturalHeight];
    }
    return [1, 1, 100, 100];
  }

  const scaleX = currentSourceImage.naturalWidth / canvas.width;
  const scaleY = currentSourceImage.naturalHeight / canvas.height;

  const origX = Math.max(1, Math.round(currentRoi[0] * scaleX));
  const origY = Math.max(1, Math.round(currentRoi[1] * scaleY));
  const origW = Math.max(1, Math.round(currentRoi[2] * scaleX));
  const origH = Math.max(1, Math.round(currentRoi[3] * scaleY));

  return [origX, origY, origW, origH];
}

function updateRoiInputs(x, y, w, h) {
  const inX = document.getElementById('roi_x');
  const inY = document.getElementById('roi_y');
  const inW = document.getElementById('roi_w');
  const inH = document.getElementById('roi_h');

  if (inX) inX.value = x;
  if (inY) inY.value = y;
  if (inW) inW.value = w;
  if (inH) inH.value = h;
}

// Method Selector
function initMethodSelector() {
  const methodSelect = document.getElementById('segMethodSelect');
  const colorGroup = document.getElementById('colorSegmentationParams');
  if (!methodSelect) return;

  methodSelect.onchange = () => {
    if (colorGroup) {
      colorGroup.style.display = methodSelect.value === 'color' ? 'block' : 'none';
    }
  };
}

// Action Buttons
function initActions() {
  const selectAllBtn = document.getElementById('selectAllRoiBtn');
  if (selectAllBtn) {
    selectAllBtn.onclick = () => {
      currentRoi = null;
      drawCanvas();
      if (currentSourceImage) {
        updateRoiInputs(1, 1, currentSourceImage.naturalWidth, currentSourceImage.naturalHeight);
        showToast('Selected full image area', 'info');
      }
    };
  }

  // 1. Generate Segmentation Mask
  const genMaskBtn = document.getElementById('generateMaskBtn');
  if (genMaskBtn) {
    genMaskBtn.onclick = async () => {
      if (!currentSourceImage) {
        showToast('Please load a saree image first.', 'warning');
        return;
      }

      const method = document.getElementById('segMethodSelect').value;
      const invert = document.getElementById('segInvertCheckbox').checked;
      const minArea = parseInt(document.getElementById('segMinArea').value || '30', 10);
      const keepLargest = document.getElementById('segKeepDominantCheckbox').checked;

      const roi = getOriginalImageRoi();

      const params = {
        invert,
        minArea,
        keepLargest
      };

      if (method === 'color') {
        const hexColor = document.getElementById('segTargetColorPicker').value;
        const r = parseInt(hexColor.slice(1, 3), 16);
        const g = parseInt(hexColor.slice(3, 5), 16);
        const b = parseInt(hexColor.slice(5, 7), 16);
        params.targetColor = [r, g, b];
        params.tolerance = parseFloat(document.getElementById('segColorTolerance').value || '50');
      }

      genMaskBtn.disabled = true;
      genMaskBtn.innerHTML = `<span class="spinner"></span> Segmenting in Octave...`;

      try {
        const res = await fetch(`${API_BASE}/segment`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            imagePath: currentSourceImage.path,
            roi,
            method,
            params
          })
        });

        const data = await res.json();
        if (!res.ok || !data.success) {
          throw new Error(data.error || 'Segmentation failed');
        }

        currentMask = {
          path: data.maskPath,
          url: data.maskUrl
        };

        const maskImg = document.getElementById('maskPreviewImg');
        const emptyMask = document.getElementById('maskEmptyState');
        if (maskImg && emptyMask) {
          emptyMask.style.display = 'none';
          maskImg.style.display = 'block';
          maskImg.src = data.maskUrl + '?t=' + Date.now();
        }

        const refineBtn = document.getElementById('refineMaskBtn');
        const extractBtn = document.getElementById('extractMotifBtn');
        if (refineBtn) refineBtn.disabled = false;
        if (extractBtn) extractBtn.disabled = false;

        showToast(`Mask generated in ${data.executionTimeMs}ms!`, 'success');
      } catch (err) {
        showToast(`Error: ${err.message}`, 'error');
      } finally {
        genMaskBtn.disabled = false;
        genMaskBtn.innerHTML = `<i class="fa-solid fa-wand-magic-sparkles"></i> Generate Mask in Octave`;
      }
    };
  }

  // 2. Refine Mask
  const refineBtn = document.getElementById('refineMaskBtn');
  if (refineBtn) {
    refineBtn.onclick = async () => {
      if (!currentMask) {
        showToast('Generate a mask first.', 'warning');
        return;
      }

      const operations = [];
      if (document.getElementById('opFillHoles').checked) operations.push('fill_holes');
      if (document.getElementById('opRemoveNoise').checked) operations.push('remove_noise');
      if (document.getElementById('opSmooth').checked) operations.push('smooth');
      if (document.getElementById('opDilate').checked) operations.push('dilate');
      if (document.getElementById('opErode').checked) operations.push('erode');

      const seSize = parseInt(document.getElementById('refineSeSize').value || '2', 10);

      refineBtn.disabled = true;
      refineBtn.innerHTML = `<span class="spinner"></span> Refining...`;

      try {
        const res = await fetch(`${API_BASE}/refine-mask`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            maskPath: currentMask.path,
            operations,
            params: { seSize }
          })
        });

        const data = await res.json();
        if (!res.ok || !data.success) throw new Error(data.error);

        currentMask = {
          path: data.refinedMaskPath,
          url: data.refinedMaskUrl
        };

        const maskImg = document.getElementById('maskPreviewImg');
        if (maskImg) {
          maskImg.src = data.refinedMaskUrl + '?t=' + Date.now();
        }

        showToast(`Mask refined in ${data.executionTimeMs}ms!`, 'success');
      } catch (err) {
        showToast(`Error: ${err.message}`, 'error');
      } finally {
        refineBtn.disabled = false;
        refineBtn.innerHTML = `<i class="fa-solid fa-broom"></i> Refine Mask in Octave`;
      }
    };
  }

  // 3. Extract Transparent Motif PNG
  const extractBtn = document.getElementById('extractMotifBtn');
  if (extractBtn) {
    extractBtn.onclick = async () => {
      if (!currentSourceImage || !currentMask) {
        showToast('Please generate and verify the mask first.', 'warning');
        return;
      }

      const padding = parseInt(document.getElementById('extractPadding').value || '5', 10);

      extractBtn.disabled = true;
      extractBtn.innerHTML = `<span class="spinner"></span> Extracting PNG in Octave...`;

      try {
        const res = await fetch(`${API_BASE}/extract-motif`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            sourceImagePath: currentSourceImage.path,
            maskPath: currentMask.path,
            padding
          })
        });

        const data = await res.json();
        if (!res.ok || !data.success) throw new Error(data.error);

        currentTransparentMotif = data;

        const motifImg = document.getElementById('motifPreviewImg');
        const emptyMotif = document.getElementById('motifEmptyState');
        const downloadBtn = document.getElementById('downloadTransparentBtn');
        const sendToCompBtn = document.getElementById('sendToCompositionBtn');
        const stats = document.getElementById('motifStatsBadge');

        if (motifImg && emptyMotif) {
          emptyMotif.style.display = 'none';
          motifImg.style.display = 'block';
          motifImg.src = data.transparentPngUrl + '?t=' + Date.now();
        }

        if (stats) {
          stats.style.display = 'flex';
          stats.innerHTML = `<span>Size: <strong>${data.dimensions.width}x${data.dimensions.height}</strong></span> <span>Alpha: <strong>True RGBA</strong></span>`;
        }

        if (downloadBtn) downloadBtn.disabled = false;
        if (sendToCompBtn) sendToCompBtn.disabled = false;

        showToast(`Extracted genuine transparent motif in ${data.executionTimeMs}ms!`, 'success');
      } catch (err) {
        showToast(`Error: ${err.message}`, 'error');
      } finally {
        extractBtn.disabled = false;
        extractBtn.innerHTML = `<i class="fa-solid fa-layer-group"></i> Extract Transparent Motif`;
      }
    };
  }

  // Download Transparent PNG
  const downloadBtn = document.getElementById('downloadTransparentBtn');
  if (downloadBtn) {
    downloadBtn.onclick = () => {
      if (currentTransparentMotif && currentTransparentMotif.transparentPngUrl) {
        downloadFile(currentTransparentMotif.transparentPngUrl, currentTransparentMotif.filename);
      }
    };
  }

  // Send to Garment Composition
  const sendToCompBtn = document.getElementById('sendToCompositionBtn');
  if (sendToCompBtn) {
    sendToCompBtn.onclick = () => {
      if (!currentTransparentMotif) return;
      sessionStorage.setItem('extractedMotif', JSON.stringify({
        path: currentTransparentMotif.transparentPngPath,
        url: currentTransparentMotif.transparentPngUrl,
        filename: currentTransparentMotif.filename,
        dimensions: currentTransparentMotif.dimensions
      }));
      window.location.href = 'composition.html';
    };
  }
}
