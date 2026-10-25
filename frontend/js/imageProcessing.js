/**
 * imageProcessing.js - Basic Image Processing Studio Controller
 * Saree Motif Segmentation Project
 */

let currentInputImage = null; // { path, url, width, height, name }
let lastProcessedResult = null;

document.addEventListener('DOMContentLoaded', async () => {
  initDropzone();
  initAlgorithmSelector();
  await initSampleSelector();
  initProcessButton();
});

// Initialize Sample Saree Chips
async function initSampleSelector() {
  const container = document.getElementById('sampleChipsContainer');
  if (!container) return;

  const samples = await loadSampleImages('saree');
  container.innerHTML = '';

  if (samples.length === 0) {
    container.innerHTML = '<span style="color:var(--text-dim);font-size:0.8rem">No sample sarees found.</span>';
    return;
  }

  samples.forEach((sample, idx) => {
    const chip = document.createElement('div');
    chip.className = 'sample-chip';
    chip.innerHTML = `
      <img src="${sample.url}" class="sample-thumb" alt="${sample.title}">
      <span>${sample.title}</span>
    `;
    chip.onclick = () => selectSample(sample);
    container.appendChild(chip);

    // Auto-select first sample on load for instant demonstration
    if (idx === 0 && !currentInputImage) {
      selectSample(sample);
    }
  });
}

function selectSample(sample) {
  currentInputImage = {
    path: sample.path,
    url: sample.url,
    name: sample.title
  };
  updateOriginalPreview(sample.url, sample.title);
  showToast(`Loaded sample: ${sample.title}`, 'info');
}

// Drag & Drop / File Input Handling
function initDropzone() {
  const dropzone = document.getElementById('imageDropzone');
  const fileInput = document.getElementById('imageFileInput');
  if (!dropzone || !fileInput) return;

  dropzone.onclick = () => fileInput.click();

  dropzone.ondragover = (e) => {
    e.preventDefault();
    dropzone.classList.add('dragover');
  };

  dropzone.ondragleave = () => {
    dropzone.classList.remove('dragover');
  };

  dropzone.ondrop = async (e) => {
    e.preventDefault();
    dropzone.classList.remove('dragover');
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileSelected(e.dataTransfer.files[0]);
    }
  };

  fileInput.onchange = (e) => {
    if (e.target.files && e.target.files[0]) {
      handleFileSelected(e.target.files[0]);
    }
  };
}

async function handleFileSelected(file) {
  try {
    showToast(`Uploading ${file.name}...`, 'info');
    const uploaded = await uploadImageFile(file);
    currentInputImage = {
      path: uploaded.path,
      url: uploaded.url,
      name: uploaded.originalName
    };
    updateOriginalPreview(uploaded.url, uploaded.originalName);
    showToast('Image uploaded successfully!', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

function updateOriginalPreview(url, name) {
  const previewImg = document.getElementById('originalPreviewImg');
  const emptyState = document.getElementById('originalEmptyState');
  const statsBadge = document.getElementById('originalStatsBadge');

  if (previewImg && emptyState) {
    emptyState.style.display = 'none';
    previewImg.style.display = 'block';
    previewImg.src = url;

    previewImg.onload = () => {
      if (statsBadge) {
        statsBadge.style.display = 'flex';
        statsBadge.innerHTML = `<span>Res: <strong>${previewImg.naturalWidth}x${previewImg.naturalHeight}</strong></span> <span>Format: <strong>${name.split('.').pop().toUpperCase()}</strong></span>`;
      }
    };
  }

  // Save to session so other pages (segmentation) can access it
  sessionStorage.setItem('currentSareeImage', JSON.stringify(currentInputImage));
}

// Algorithm Selector & Dynamic Parameter Panels
function initAlgorithmSelector() {
  const select = document.getElementById('algorithmSelect');
  if (!select) return;

  select.onchange = () => {
    renderParameterControls(select.value);
  };

  renderParameterControls(select.value);
}

function renderParameterControls(algo) {
  const container = document.getElementById('dynamicParamsContainer');
  if (!container) return;

  let html = '';

  switch (algo) {
    case 'binaryThreshold':
      html = `
        <div class="form-group">
          <label class="form-label">Threshold Cutoff: <span class="form-val-badge" id="threshVal">-1 (Otsu Auto)</span></label>
          <input type="range" class="form-range" id="param_threshold" min="-1" max="255" value="-1" 
            oninput="document.getElementById('threshVal').innerText = this.value == -1 ? '-1 (Otsu Auto)' : this.value">
        </div>
        <div class="form-group">
          <label class="form-checkbox-label">
            <input type="checkbox" class="form-checkbox" id="param_invert">
            <span>Invert Foreground / Background</span>
          </label>
        </div>
      `;
      break;

    case 'adaptiveThreshold':
      html = `
        <div class="form-group">
          <label class="form-label">Window Size (W x W): <span class="form-val-badge" id="windowVal">25 px</span></label>
          <input type="range" class="form-range" id="param_windowSize" min="5" max="65" step="2" value="25"
            oninput="document.getElementById('windowVal').innerText = this.value + ' px'">
        </div>
        <div class="form-group">
          <label class="form-label">Offset Constant C: <span class="form-val-badge" id="cVal">5</span></label>
          <input type="range" class="form-range" id="param_constantC" min="-15" max="30" value="5"
            oninput="document.getElementById('cVal').innerText = this.value">
        </div>
        <div class="form-group">
          <label class="form-checkbox-label">
            <input type="checkbox" class="form-checkbox" id="param_invert">
            <span>Invert Foreground / Background</span>
          </label>
        </div>
      `;
      break;

    case 'gaussianFilter':
      html = `
        <div class="form-group">
          <label class="form-label">Kernel Size: <span class="form-val-badge" id="kVal">5 px</span></label>
          <input type="range" class="form-range" id="param_kernelSize" min="3" max="15" step="2" value="5"
            oninput="document.getElementById('kVal').innerText = this.value + ' px'">
        </div>
        <div class="form-group">
          <label class="form-label">Sigma (Blur Strength): <span class="form-val-badge" id="sigVal">1.5</span></label>
          <input type="range" class="form-range" id="param_sigma" min="0.5" max="5.0" step="0.25" value="1.5"
            oninput="document.getElementById('sigVal').innerText = this.value">
        </div>
      `;
      break;

    case 'medianFilter':
      html = `
        <div class="form-group">
          <label class="form-label">Window Neighborhood: <span class="form-val-badge" id="medVal">3 x 3</span></label>
          <input type="range" class="form-range" id="param_windowSize" min="3" max="9" step="2" value="3"
            oninput="document.getElementById('medVal').innerText = this.value + ' x ' + this.value">
        </div>
      `;
      break;

    case 'sharpenImage':
      html = `
        <div class="form-group">
          <label class="form-label">Sharpen Boost Strength: <span class="form-val-badge" id="sharpVal">1.2x</span></label>
          <input type="range" class="form-range" id="param_strength" min="0.2" max="3.0" step="0.1" value="1.2"
            oninput="document.getElementById('sharpVal').innerText = this.value + 'x'">
        </div>
      `;
      break;

    case 'contrastEnhancement':
      html = `
        <div class="form-group">
          <label class="form-label">Low Intensity Clip (%): <span class="form-val-badge" id="lowVal">1%</span></label>
          <input type="range" class="form-range" id="param_lowClip" min="0" max="0.1" step="0.005" value="0.01"
            oninput="document.getElementById('lowVal').innerText = Math.round(this.value * 100) + '%'">
        </div>
        <div class="form-group">
          <label class="form-label">High Intensity Clip (%): <span class="form-val-badge" id="highVal">99%</span></label>
          <input type="range" class="form-range" id="param_highClip" min="0.9" max="1.0" step="0.005" value="0.99"
            oninput="document.getElementById('highVal').innerText = Math.round(this.value * 100) + '%'">
        </div>
      `;
      break;

    case 'cannyEdgeDetection':
      html = `
        <div class="form-group">
          <label class="form-label">Gaussian Pre-Filter Sigma: <span class="form-val-badge" id="cannySigVal">1.41</span></label>
          <input type="range" class="form-range" id="param_sigma" min="0.5" max="3.0" step="0.1" value="1.41"
            oninput="document.getElementById('cannySigVal').innerText = this.value">
        </div>
      `;
      break;

    case 'sobelEdgeDetection':
      html = `
        <div class="form-group">
          <label class="form-label">Gradient Magnitude Threshold: <span class="form-val-badge" id="sobelVal">45</span></label>
          <input type="range" class="form-range" id="param_threshold" min="0" max="150" value="45"
            oninput="document.getElementById('sobelVal').innerText = this.value == 0 ? 'Normalized Gradient' : this.value">
        </div>
      `;
      break;

    case 'morphologicalErosion':
    case 'morphologicalDilation':
    case 'morphologicalOpening':
    case 'morphologicalClosing':
      html = `
        <div class="form-group">
          <label class="form-label">Structuring Element Shape:</label>
          <select class="form-select" id="param_seShape">
            <option value="disk" selected>Disk (Radial)</option>
            <option value="square">Square</option>
            <option value="diamond">Diamond</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Element Size / Radius: <span class="form-val-badge" id="seVal">2 px</span></label>
          <input type="range" class="form-range" id="param_seSize" min="1" max="8" value="2"
            oninput="document.getElementById('seVal').innerText = this.value + ' px'">
        </div>
      `;
      break;

    default:
      html = `<div style="font-size:0.85rem;color:var(--text-dim);padding:0.5rem 0;">Standard mathematical defaults applied. No extra parameters required.</div>`;
      break;
  }

  container.innerHTML = html;
}

// Harvest Parameters from DOM
function collectParameters(algo) {
  const params = {};

  const getNum = (id) => {
    const el = document.getElementById(id);
    return el ? parseFloat(el.value) : undefined;
  };
  const getBool = (id) => {
    const el = document.getElementById(id);
    return el ? el.checked : false;
  };
  const getStr = (id) => {
    const el = document.getElementById(id);
    return el ? el.value : undefined;
  };

  switch (algo) {
    case 'binaryThreshold':
      params.threshold = getNum('param_threshold');
      params.invert = getBool('param_invert');
      break;
    case 'adaptiveThreshold':
      params.windowSize = getNum('param_windowSize');
      params.constantC = getNum('param_constantC');
      params.invert = getBool('param_invert');
      break;
    case 'gaussianFilter':
      params.kernelSize = getNum('param_kernelSize');
      params.sigma = getNum('param_sigma');
      break;
    case 'medianFilter':
      params.windowSize = getNum('param_windowSize');
      break;
    case 'sharpenImage':
      params.strength = getNum('param_strength');
      break;
    case 'contrastEnhancement':
      params.lowClip = getNum('param_lowClip');
      params.highClip = getNum('param_highClip');
      break;
    case 'cannyEdgeDetection':
      params.sigma = getNum('param_sigma');
      break;
    case 'sobelEdgeDetection':
      params.threshold = getNum('param_threshold');
      break;
    case 'morphologicalErosion':
    case 'morphologicalDilation':
    case 'morphologicalOpening':
    case 'morphologicalClosing':
      params.seShape = getStr('param_seShape');
      params.seSize = getNum('param_seSize');
      break;
  }

  return params;
}

// Process Image Action
function initProcessButton() {
  const btn = document.getElementById('processBtn');
  if (!btn) return;

  btn.onclick = async () => {
    if (!currentInputImage) {
      showToast('Please upload or select a saree image first.', 'warning');
      return;
    }

    const algoSelect = document.getElementById('algorithmSelect');
    const algo = algoSelect ? algoSelect.value : 'grayscale';
    const params = collectParameters(algo);

    btn.disabled = true;
    btn.innerHTML = `<span class="spinner"></span> Processing in Octave...`;

    try {
      const res = await fetch(`${API_BASE}/process`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          algorithm: algo,
          imagePath: currentInputImage.path,
          params
        })
      });

      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.error || 'Octave algorithm execution failed');
      }

      lastProcessedResult = data;
      updateProcessedPreview(data);
      showToast(`Finished '${algo}' in ${data.executionTimeMs}ms!`, 'success');
    } catch (err) {
      console.error(err);
      showToast(`Error: ${err.message}`, 'error');
    } finally {
      btn.disabled = false;
      btn.innerHTML = `<i class="fa-solid fa-bolt"></i> Process Image with Octave`;
    }
  };

  const downloadBtn = document.getElementById('downloadProcessedBtn');
  if (downloadBtn) {
    downloadBtn.onclick = () => {
      if (lastProcessedResult && lastProcessedResult.relativeUrl) {
        downloadFile(lastProcessedResult.relativeUrl, lastProcessedResult.filename);
      }
    };
  }

  const sendToSegBtn = document.getElementById('sendToSegmentationBtn');
  if (sendToSegBtn) {
    sendToSegBtn.onclick = () => {
      if (!currentInputImage) {
        showToast('Please select an image first.', 'warning');
        return;
      }
      sessionStorage.setItem('currentSareeImage', JSON.stringify(currentInputImage));
      window.location.href = 'pages/segmentation.html';
    };
  }
}

function updateProcessedPreview(data) {
  const previewImg = document.getElementById('processedPreviewImg');
  const emptyState = document.getElementById('processedEmptyState');
  const statsBadge = document.getElementById('processedStatsBadge');
  const downloadBtn = document.getElementById('downloadProcessedBtn');

  if (previewImg && emptyState) {
    emptyState.style.display = 'none';
    previewImg.style.display = 'block';
    previewImg.src = data.relativeUrl + '?t=' + Date.now();

    if (statsBadge) {
      statsBadge.style.display = 'flex';
      statsBadge.innerHTML = `<span>Algo: <strong>${data.algorithm}</strong></span> <span>Time: <strong>${data.executionTimeMs}ms</strong></span>`;
    }

    if (downloadBtn) downloadBtn.disabled = false;
  }
}
