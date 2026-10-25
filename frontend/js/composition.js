/**
 * composition.js - Garment Motif Placement & Alpha Compositing Controller
 * Saree Motif Segmentation Project
 */

let destinationGarment = null; // { path, url, naturalWidth, naturalHeight, name }
let currentMotif = null;        // { path, url, dimensions, name }
let lastCompositeResult = null;
let debounceTimer = null;

document.addEventListener('DOMContentLoaded', async () => {
  initDestinationSelector();
  initMotifSelector();
  initCompositionControls();

  // Check if an extracted motif was passed from segmentation
  const savedMotif = sessionStorage.getItem('extractedMotif');
  if (savedMotif) {
    try {
      const parsed = JSON.parse(savedMotif);
      setMotif(parsed);
    } catch (e) {}
  }
});

// Destination Garment Setup
async function initDestinationSelector() {
  const container = document.getElementById('destSampleChips');
  const fileInput = document.getElementById('destFileInput');

  if (fileInput) {
    fileInput.onchange = async (e) => {
      if (e.target.files && e.target.files[0]) {
        try {
          showToast(`Uploading garment ${e.target.files[0].name}...`, 'info');
          const uploaded = await uploadImageFile(e.target.files[0]);
          setDestination({
            path: uploaded.path,
            url: uploaded.url,
            name: uploaded.originalName
          });
          showToast('Destination garment uploaded!', 'success');
        } catch (err) {
          showToast(err.message, 'error');
        }
      }
    };
  }

  if (container) {
    const samples = await loadSampleImages('destination');
    container.innerHTML = '';

    samples.forEach((sample, idx) => {
      const chip = document.createElement('div');
      chip.className = 'sample-chip';
      chip.innerHTML = `
        <img src="${sample.url}" class="sample-thumb" alt="${sample.title}">
        <span>${sample.title}</span>
      `;
      chip.onclick = () => {
        setDestination({
          path: sample.path,
          url: sample.url,
          name: sample.title
        });
        showToast(`Loaded ${sample.title}`, 'info');
      };
      container.appendChild(chip);

      // Default to first destination sample
      if (idx === 0 && !destinationGarment) {
        setDestination({
          path: sample.path,
          url: sample.url,
          name: sample.title
        });
      }
    });
  }
}

function setDestination(garment) {
  destinationGarment = garment;
  const img = new Image();
  img.onload = () => {
    destinationGarment.naturalWidth = img.naturalWidth;
    destinationGarment.naturalHeight = img.naturalHeight;

    const preview = document.getElementById('destPreviewImg');
    const empty = document.getElementById('destEmptyState');
    const stats = document.getElementById('destStatsBadge');

    if (preview && empty) {
      empty.style.display = 'none';
      preview.style.display = 'block';
      preview.src = garment.url;

      if (stats) {
        stats.style.display = 'flex';
        stats.innerHTML = `<span>Canvas: <strong>${img.naturalWidth}x${img.naturalHeight}</strong></span>`;
      }
    }

    // Update X and Y slider bounds
    const posX = document.getElementById('comp_posX');
    const posY = document.getElementById('comp_posY');
    if (posX) posX.max = img.naturalWidth;
    if (posY) posY.max = img.naturalHeight;
  };
  img.src = garment.url;
}

// Motif Setup
function initMotifSelector() {
  const fileInput = document.getElementById('motifFileInput');
  if (fileInput) {
    fileInput.onchange = async (e) => {
      if (e.target.files && e.target.files[0]) {
        try {
          showToast(`Uploading transparent motif ${e.target.files[0].name}...`, 'info');
          const uploaded = await uploadImageFile(e.target.files[0]);
          setMotif({
            path: uploaded.path,
            url: uploaded.url,
            name: uploaded.originalName
          });
          showToast('Transparent motif loaded!', 'success');
        } catch (err) {
          showToast(err.message, 'error');
        }
      }
    };
  }
}

function setMotif(motif) {
  currentMotif = motif;
  const preview = document.getElementById('compMotifThumb');
  const empty = document.getElementById('compMotifEmpty');
  const nameEl = document.getElementById('compMotifName');

  if (preview && empty) {
    empty.style.display = 'none';
    preview.style.display = 'block';
    preview.src = motif.url;
    if (nameEl) nameEl.innerText = motif.name || motif.filename || 'Extracted Motif (RGBA)';
  }

  showToast('Motif ready for placement!', 'info');
}

// Composition Controls & Octave Dispatch
function initCompositionControls() {
  const controls = ['comp_posX', 'comp_posY', 'comp_scale', 'comp_angle', 'comp_opacity', 'comp_flipH', 'comp_flipV'];

  controls.forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;

    el.oninput = () => {
      updateValueBadge(id, el);
    };
  });

  // Interactive Click-to-Position on Destination Garment
  const destPreview = document.getElementById('destPreviewImg');
  if (destPreview) {
    destPreview.style.cursor = 'crosshair';
    destPreview.onclick = (e) => {
      if (!destinationGarment || !destinationGarment.naturalWidth) return;

      const rect = destPreview.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const clickY = e.clientY - rect.top;

      const scaleX = destinationGarment.naturalWidth / rect.width;
      const scaleY = destinationGarment.naturalHeight / rect.height;

      const targetX = Math.round(clickX * scaleX);
      const targetY = Math.round(clickY * scaleY);

      const inX = document.getElementById('comp_posX');
      const inY = document.getElementById('comp_posY');
      if (inX) {
        inX.value = targetX;
        updateValueBadge('comp_posX', inX);
      }
      if (inY) {
        inY.value = targetY;
        updateValueBadge('comp_posY', inY);
      }

      showToast(`Position set to (${targetX}, ${targetY})`, 'info', 2000);
    };
  }

  // Render Button
  const composeBtn = document.getElementById('renderCompositeBtn');
  if (composeBtn) {
    composeBtn.onclick = () => renderComposite(false);
  }

  // Download Button
  const downloadBtn = document.getElementById('downloadCompositeBtn');
  if (downloadBtn) {
    downloadBtn.onclick = () => {
      if (lastCompositeResult && lastCompositeResult.compositeUrl) {
        downloadFile(lastCompositeResult.compositeUrl, lastCompositeResult.filename);
      }
    };
  }
}

function updateValueBadge(id, el) {
  const badgeMap = {
    'comp_posX': 'badge_posX',
    'comp_posY': 'badge_posY',
    'comp_scale': 'badge_scale',
    'comp_angle': 'badge_angle',
    'comp_opacity': 'badge_opacity'
  };

  const badgeId = badgeMap[id];
  if (!badgeId) return;

  const badge = document.getElementById(badgeId);
  if (!badge) return;

  if (id === 'comp_scale') badge.innerText = el.value + 'x';
  else if (id === 'comp_angle') badge.innerText = el.value + '°';
  else if (id === 'comp_opacity') badge.innerText = Math.round(el.value * 100) + '%';
  else badge.innerText = el.value + ' px';
}

async function renderComposite(isDebounced = false) {
  if (!destinationGarment) {
    showToast('Please select a destination garment first.', 'warning');
    return;
  }
  if (!currentMotif) {
    showToast('Please extract or upload a motif first.', 'warning');
    return;
  }

  const btn = document.getElementById('renderCompositeBtn');
  if (btn) {
    btn.disabled = true;
    btn.innerHTML = `<span class="spinner"></span> Compositing in Octave...`;
  }

  const posX = parseFloat(document.getElementById('comp_posX').value || '100');
  const posY = parseFloat(document.getElementById('comp_posY').value || '100');
  const scale = parseFloat(document.getElementById('comp_scale').value || '1.0');
  const angle = parseFloat(document.getElementById('comp_angle').value || '0.0');
  const opacity = parseFloat(document.getElementById('comp_opacity').value || '1.0');
  const flipH = document.getElementById('comp_flipH').checked;
  const flipV = document.getElementById('comp_flipV').checked;

  try {
    const res = await fetch(`${API_BASE}/compose`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        destImagePath: destinationGarment.path,
        motifPath: currentMotif.path,
        posX,
        posY,
        scale,
        angle,
        opacity,
        flipH,
        flipV
      })
    });

    const data = await res.json();
    if (!res.ok || !data.success) throw new Error(data.error);

    lastCompositeResult = data;

    const preview = document.getElementById('compositePreviewImg');
    const empty = document.getElementById('compositeEmptyState');
    const stats = document.getElementById('compositeStatsBadge');
    const downloadBtn = document.getElementById('downloadCompositeBtn');

    if (preview && empty) {
      empty.style.display = 'none';
      preview.style.display = 'block';
      preview.src = data.compositeUrl + '?t=' + Date.now();

      if (stats) {
        stats.style.display = 'flex';
        stats.innerHTML = `<span>Octave Blended in <strong>${data.executionTimeMs}ms</strong></span> <span>Porter-Duff Alpha Over</span>`;
      }
      if (downloadBtn) downloadBtn.disabled = false;
    }

    showToast(`Composited motif in ${data.executionTimeMs}ms!`, 'success');
  } catch (err) {
    showToast(`Error: ${err.message}`, 'error');
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.innerHTML = `<i class="fa-solid fa-wand-magic-sparkles"></i> Render Composite in Octave`;
    }
  }
}
