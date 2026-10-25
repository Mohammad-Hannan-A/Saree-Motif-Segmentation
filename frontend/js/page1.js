/**
 * page1.js - Logic for Page 1: Image Upload & Grayscale Conversion
 * Communicates with GNU Octave backend via REST API.
 */

document.addEventListener('DOMContentLoaded', () => {
  // Initialize Header Navigation for Step 1
  window.sareeSession.initHeader(1);

  // UI Elements
  const dropzone = document.getElementById('dropzone');
  const fileInput = document.getElementById('file-input');
  const samplesContainer = document.getElementById('samples-container');
  const btnConvertGrayscale = document.getElementById('btn-convert-grayscale');
  const btnDownloadOriginal = document.getElementById('btn-download-original');
  const btnDownloadGray = document.getElementById('btn-download-gray');
  const btnSaveContinueTop = document.getElementById('btn-save-continue');
  const btnSaveContinueBottom = document.getElementById('btn-save-continue-bottom');
  const origImg = document.getElementById('orig-img');
  const origEmpty = document.getElementById('orig-empty');
  const grayImg = document.getElementById('gray-img');
  const grayEmpty = document.getElementById('gray-empty');
  const loadingOverlay = document.getElementById('loading-overlay');
  const loadingTitle = document.getElementById('loading-title');
  const loadingDesc = document.getElementById('loading-desc');
  const octaveTimerStatus = document.getElementById('octave-timer-status');

  // Load any existing session state
  restoreExistingState();

  // Load sample images from backend
  loadSamples();

  // Setup Drag and Drop
  dropzone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropzone.classList.add('dragover');
  });

  dropzone.addEventListener('dragleave', () => {
    dropzone.classList.remove('dragover');
  });

  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.classList.remove('dragover');
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileUpload(e.dataTransfer.files[0]);
    }
  });

  fileInput.addEventListener('change', () => {
    if (fileInput.files && fileInput.files[0]) {
      handleFileUpload(fileInput.files[0]);
    }
  });

  // Convert to Grayscale click
  btnConvertGrayscale.addEventListener('click', () => {
    runGrayscaleConversion();
  });

  // Download buttons
  btnDownloadOriginal.addEventListener('click', () => {
    const orig = window.sareeSession.getOriginalImage();
    if (orig && orig.filename) {
      window.location.href = `/api/download/${orig.filename}`;
    }
  });

  btnDownloadGray.addEventListener('click', () => {
    const gray = window.sareeSession.getGrayscaleImage();
    if (gray && gray.filename) {
      window.location.href = `/api/download/${gray.filename}`;
    }
  });

  // Save & Continue
  function onContinue() {
    const orig = window.sareeSession.getOriginalImage();
    const gray = window.sareeSession.getGrayscaleImage();
    if (!orig) {
      window.sareeSession.showToast('Please upload an image first.', 'error');
      return;
    }
    if (!gray) {
      window.sareeSession.showToast('Please convert the image to grayscale before proceeding to Page 2.', 'warning');
      return;
    }
    window.sareeSession.showToast('Saved session data successfully! Proceeding to Page 2.', 'success');
    setTimeout(() => {
      window.location.href = 'page2.html';
    }, 400);
  }

  btnSaveContinueTop.addEventListener('click', onContinue);
  btnSaveContinueBottom.addEventListener('click', onContinue);

  // --- Handlers ---

  function restoreExistingState() {
    const orig = window.sareeSession.getOriginalImage();
    if (orig && orig.url) {
      displayOriginalImage(orig.url);
      btnConvertGrayscale.disabled = false;
      btnDownloadOriginal.disabled = false;
    }

    const gray = window.sareeSession.getGrayscaleImage();
    if (gray && gray.url) {
      displayGrayscaleImage(gray.url);
      btnDownloadGray.disabled = false;
      btnSaveContinueTop.disabled = false;
      btnSaveContinueBottom.disabled = false;
    }
  }

  async function handleFileUpload(file) {
    if (!file.type.match(/^image\/(png|jpeg|jpg)$/i)) {
      window.sareeSession.showToast('Unsupported file type. Please upload a PNG or JPEG image.', 'error');
      return;
    }

    const formData = new FormData();
    formData.append('image', file);

    showLoading('Uploading Image', 'Transferring image file to backend storage...');

    try {
      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData
      });

      const data = await res.json();
      hideLoading();

      if (!data.success) {
        throw new Error(data.error || 'Upload failed');
      }

      const imgData = {
        filename: data.file.filename,
        originalName: data.file.originalName,
        path: data.file.path,
        url: data.file.url
      };

      window.sareeSession.setOriginalImage(imgData);
      // Reset subsequent grayscale when a fresh image is uploaded
      window.sareeSession.setGrayscaleImage(null);

      displayOriginalImage(imgData.url);
      resetGrayscalePreview();

      btnConvertGrayscale.disabled = false;
      btnDownloadOriginal.disabled = false;
      btnSaveContinueTop.disabled = true;
      btnSaveContinueBottom.disabled = true;

      window.sareeSession.showToast('Original saree image uploaded successfully!', 'success');
    } catch (err) {
      hideLoading();
      window.sareeSession.showToast(`Upload failed: ${err.message}`, 'error');
    }
  }

  async function loadSamples() {
    try {
      const res = await fetch('/api/samples');
      const data = await res.json();

      if (!data.success || !data.samples || data.samples.length === 0) {
        samplesContainer.innerHTML = '<span class="text-muted" style="font-size:0.75rem;">No samples found.</span>';
        return;
      }

      const sareeSamples = data.samples.filter(s => s.type === 'saree');
      samplesContainer.innerHTML = '';

      sareeSamples.forEach(sample => {
        const thumb = document.createElement('div');
        thumb.className = 'sample-thumb-item';
        thumb.title = sample.title;
        thumb.innerHTML = `<img src="${sample.url}" alt="${sample.title}">`;

        thumb.addEventListener('click', () => {
          document.querySelectorAll('.sample-thumb-item').forEach(el => el.classList.remove('active'));
          thumb.classList.add('active');

          const imgData = {
            filename: sample.filename,
            originalName: sample.title,
            path: sample.path,
            url: sample.url
          };

          window.sareeSession.setOriginalImage(imgData);
          window.sareeSession.setGrayscaleImage(null);

          displayOriginalImage(imgData.url);
          resetGrayscalePreview();

          btnConvertGrayscale.disabled = false;
          btnDownloadOriginal.disabled = false;
          btnSaveContinueTop.disabled = true;
          btnSaveContinueBottom.disabled = true;

          window.sareeSession.showToast(`Loaded sample: ${sample.title}`, 'info');
        });

        samplesContainer.appendChild(thumb);
      });
    } catch (e) {
      console.warn('Could not load academic samples:', e);
    }
  }

  async function runGrayscaleConversion() {
    const orig = window.sareeSession.getOriginalImage();
    if (!orig || !orig.path) {
      window.sareeSession.showToast('No source image selected.', 'error');
      return;
    }

    showLoading('Executing GNU Octave', 'Running grayscale_conversion.m via child process...');

    try {
      const res = await fetch('/api/process', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          algorithm: 'grayscale_conversion',
          imagePath: orig.path,
          params: {}
        })
      });

      const data = await res.json();
      hideLoading();

      if (!data.success) {
        throw new Error(data.error || 'Grayscale conversion failed in Octave');
      }

      const grayData = {
        filename: data.filename,
        path: data.outputPath,
        url: data.relativeUrl,
        executionTimeMs: data.executionTimeMs
      };

      window.sareeSession.setGrayscaleImage(grayData);
      displayGrayscaleImage(grayData.url);

      btnDownloadGray.disabled = false;
      btnSaveContinueTop.disabled = false;
      btnSaveContinueBottom.disabled = false;

      octaveTimerStatus.textContent = `Octave converted RGB to Grayscale in ${data.executionTimeMs} ms (${data.imageInfo ? `${data.imageInfo.width}×${data.imageInfo.height} px` : ''}).`;

      window.sareeSession.showToast('Grayscale conversion completed by GNU Octave!', 'success');
    } catch (err) {
      hideLoading();
      window.sareeSession.showToast(`Octave conversion error: ${err.message}`, 'error');
    }
  }

  function displayOriginalImage(url) {
    origEmpty.style.display = 'none';
    origImg.style.display = 'block';
    origImg.src = url;
  }

  function displayGrayscaleImage(url) {
    grayEmpty.style.display = 'none';
    grayImg.style.display = 'block';
    grayImg.src = url;
  }

  function resetGrayscalePreview() {
    grayImg.style.display = 'none';
    grayEmpty.style.display = 'flex';
    btnDownloadGray.disabled = true;
    octaveTimerStatus.textContent = 'Ready for processing.';
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
