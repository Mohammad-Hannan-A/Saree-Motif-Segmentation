function processRequest(jsonFilePath)
% processRequest.m
% Controlled backend dispatcher function for GNU Octave.
% Executed non-interactively by the Node.js backend.
%
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Usage:
%   octave-cli --no-gui --quiet --no-history processRequest.m "path/to/request.json"

  % Start execution timer
  t0 = tic();

  % Ensure output is unbuffered
  more off;

  % 1. Load required GNU Octave packages
  try
    pkg load image;
  catch err
    % Image package might already be loaded or built-in
  end_try_catch

  % 2. Add algorithms folder to Octave search path
  scriptDir = fileparts(mfilename('fullpath'));
  projectRoot = fileparts(scriptDir);
  algoDir = fullfile(projectRoot, 'algorithms');
  addpath(algoDir);

  % 3. Read command-line arguments if not passed directly
  if nargin < 1 || isempty(jsonFilePath)
    args = argv();
    if isempty(args)
      emitError('No JSON request file argument provided to processRequest.m');
      exit(1);
    endif
    jsonFilePath = args{1};
  endif

  if ~exist(jsonFilePath, 'file')
    emitError(sprintf('Request configuration file not found: %s', jsonFilePath));
    exit(1);
  endif

  % 4. Read and decode JSON request payload
  try
    jsonText = fileread(jsonFilePath);
    req = jsondecode(jsonText);
  catch err
    emitError(sprintf('Failed to parse request JSON: %s', err.message));
    exit(1);
  end_try_catch

  % 5. Validate mandatory fields
  if ~isfield(req, 'algorithm') || isempty(req.algorithm)
    emitError('Missing mandatory field "algorithm" in request payload');
    exit(1);
  endif

  algo = req.algorithm;
  outputPath = '';
  if isfield(req, 'outputPath') && ~isempty(req.outputPath)
    outputPath = req.outputPath;
    outDir = fileparts(outputPath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
      mkdir(outDir);
    endif
  endif

  if ~isfield(req, 'params') || isempty(req.params)
    req.params = struct();
  endif

  metrics = struct();

  % 6. Dispatch to target algorithm
  try
    switch algo
      % --- PAGE 1 & BASIC ALGORITHMS ---
      case {'grayscale', 'grayscale_conversion'}
        img = imread(req.inputPath);
        outImg = grayscale_conversion(img);
        imwrite(outImg, outputPath);

      case {'imageNegative', 'image_negative'}
        img = imread(req.inputPath);
        outImg = image_negative(img);
        imwrite(outImg, outputPath);

      case {'image_resizing', 'imageResizing'}
        img = imread(req.inputPath);
        targetW = getField(req.params, 'targetWidth', round(size(img, 2) * 0.75));
        targetH = getField(req.params, 'targetHeight', round(size(img, 1) * 0.75));
        preserveAspect = getField(req.params, 'preserveAspect', true);
        outImg = image_resizing(img, targetW, targetH, preserveAspect);
        imwrite(outImg, outputPath);
        metrics.width = size(outImg, 2);
        metrics.height = size(outImg, 1);

      case {'binaryThreshold', 'image_thresholding', 'imageThresholding'}
        img = imread(req.inputPath);
        thresh = getField(req.params, 'threshold', -1);
        invert = getField(req.params, 'invert', false);
        [outImg, calcT] = image_thresholding(img, thresh, invert);
        imwrite(outImg, outputPath);
        metrics.threshold = calcT;

      case {'adaptiveThreshold', 'adaptive_threshold'}
        img = imread(req.inputPath);
        wSize = getField(req.params, 'windowSize', 25);
        constC = getField(req.params, 'constantC', 5);
        invert = getField(req.params, 'invert', false);
        outImg = adaptiveThreshold(img, wSize, constC, invert);
        imwrite(outImg, outputPath);

      case {'gaussianFilter', 'gaussian_filtering', 'gaussianFiltering'}
        img = imread(req.inputPath);
        kSize = getField(req.params, 'kernelSize', 5);
        sig = getField(req.params, 'sigma', 1.5);
        outImg = gaussian_filtering(img, kSize, sig);
        imwrite(outImg, outputPath);

      case {'rgb_to_hsv_conversion', 'rgbToHsvConversion'}
        img = imread(req.inputPath);
        [outImg, ~, ~, ~] = rgb_to_hsv_conversion(img);
        imwrite(outImg, outputPath);

      % --- PAGE 3: METHOD 1 - IMAGE ENHANCEMENT ---
      case {'histogramEqualization', 'histogram_equalization'}
        img = imread(req.inputPath);
        [outImg, hBefore, hAfter] = histogram_equalization(img);
        imwrite(outImg, outputPath);
        metrics.histBefore = hBefore(:)';
        metrics.histAfter = hAfter(:)';

      case {'contrast_stretching', 'contrastStretching', 'contrastEnhancement'}
        img = imread(req.inputPath);
        lowClip = getField(req.params, 'lowClip', 0.01);
        highClip = getField(req.params, 'highClip', 0.99);
        outImg = contrast_stretching(img, lowClip, highClip);
        imwrite(outImg, outputPath);

      case {'medianFilter', 'median_filtering', 'medianFiltering'}
        img = imread(req.inputPath);
        wSize = getField(req.params, 'windowSize', 3);
        outImg = median_filtering(img, wSize);
        imwrite(outImg, outputPath);

      case {'sharpenImage', 'sharpen_image'}
        img = imread(req.inputPath);
        strength = getField(req.params, 'strength', 1.0);
        outImg = sharpenImage(img, strength);
        imwrite(outImg, outputPath);

      % --- PAGE 3: METHOD 2 - IMAGE SEGMENTATION ---
      case {'kmeans_segmentation', 'kmeansSegmentation'}
        img = imread(req.inputPath);
        k = getField(req.params, 'numClusters', 3);
        maxIter = getField(req.params, 'maxIterations', 15);
        [outImg, labels, centroids] = kmeans_segmentation(img, k, maxIter);
        imwrite(outImg, outputPath);
        metrics.clusters = k;
        metrics.centroids = centroids;

      case {'region_based_segmentation', 'regionBasedSegmentation'}
        img = imread(req.inputPath);
        seed = getField(req.params, 'seedPoint', []);
        tol = getField(req.params, 'tolerance', 35);
        [outImg, mask] = region_based_segmentation(img, seed, tol);
        imwrite(outImg, outputPath);
        if isfield(req.params, 'maskOutputPath') && ~isempty(req.params.maskOutputPath)
          imwrite(uint8(mask * 255), req.params.maskOutputPath);
        endif

      case {'colorSegmentation', 'color_based_segmentation', 'colorBasedSegmentation'}
        img = imread(req.inputPath);
        tColor = getField(req.params, 'targetColor', [218, 165, 32]);
        tol = getField(req.params, 'tolerance', 55);
        cSpace = getField(req.params, 'colorSpace', 'RGB');
        [outImg, mask] = color_based_segmentation(img, tColor, tol, cSpace);
        imwrite(outImg, outputPath);
        if isfield(req.params, 'maskOutputPath') && ~isempty(req.params.maskOutputPath)
          imwrite(uint8(mask * 255), req.params.maskOutputPath);
        endif

      % --- PAGE 3: METHOD 3 - EDGE DETECTION ---
      case {'sobelEdgeDetection', 'sobel_edge_detection'}
        img = imread(req.inputPath);
        thresh = getField(req.params, 'threshold', 50);
        outImg = sobel_edge_detection(img, thresh);
        imwrite(outImg, outputPath);

      case {'prewitt_edge_detection', 'prewittEdgeDetection'}
        img = imread(req.inputPath);
        thresh = getField(req.params, 'threshold', 45);
        outImg = prewitt_edge_detection(img, thresh);
        imwrite(outImg, outputPath);

      case {'cannyEdgeDetection', 'canny_edge_detection'}
        img = imread(req.inputPath);
        thresh = getField(req.params, 'thresholds', []);
        sig = getField(req.params, 'sigma', sqrt(2));
        outImg = canny_edge_detection(img, thresh, sig);
        imwrite(outImg, outputPath);

      case {'contourDetection', 'contour_detection'}
        img = imread(req.inputPath);
        thickness = getField(req.params, 'thickness', 1);
        [contourMap, overlayImg] = contourDetection(img, thickness);
        imwrite(overlayImg, outputPath);

      % --- PAGE 3: METHOD 4 - MORPHOLOGICAL PROCESSING ---
      case {'morphologicalDilation', 'morphological_dilation'}
        img = imread(req.inputPath);
        seShape = getField(req.params, 'seShape', 'disk');
        seSize = getField(req.params, 'seSize', 2);
        outImg = morphological_dilation(img, seShape, seSize);
        imwrite(outImg, outputPath);

      case {'morphologicalErosion', 'morphological_erosion'}
        img = imread(req.inputPath);
        seShape = getField(req.params, 'seShape', 'disk');
        seSize = getField(req.params, 'seSize', 2);
        outImg = morphological_erosion(img, seShape, seSize);
        imwrite(outImg, outputPath);

      case {'morphologicalOpening', 'morphological_opening'}
        img = imread(req.inputPath);
        seShape = getField(req.params, 'seShape', 'disk');
        seSize = getField(req.params, 'seSize', 2);
        outImg = morphological_open_close(img, 'opening', seShape, seSize);
        imwrite(outImg, outputPath);

      case {'morphologicalClosing', 'morphological_closing'}
        img = imread(req.inputPath);
        seShape = getField(req.params, 'seShape', 'disk');
        seSize = getField(req.params, 'seSize', 2);
        outImg = morphological_open_close(img, 'closing', seShape, seSize);
        imwrite(outImg, outputPath);

      case {'morphological_open_close', 'morphologicalOpenClose'}
        img = imread(req.inputPath);
        op = getField(req.params, 'operation', 'both');
        seShape = getField(req.params, 'seShape', 'disk');
        seSize = getField(req.params, 'seSize', 2);
        outImg = morphological_open_close(img, op, seShape, seSize);
        imwrite(outImg, outputPath);

      % --- PAGE 4: EXTRACTION & COMPOSITION ---
      case {'bounding_box_crop', 'boundingBoxCrop'}
        img = imread(req.inputPath);
        roi = getField(req.params, 'bbox', []);
        if isempty(roi) && isfield(req.params, 'roi')
          roi = req.params.roi;
        endif
        [outImg, actualBbox] = bounding_box_crop(img, roi);
        imwrite(outImg, outputPath);
        metrics.bbox = actualBbox;
        metrics.width = size(outImg, 2);
        metrics.height = size(outImg, 1);

      case {'segmentMotif', 'segment_motif'}
        img = imread(req.inputPath);
        roi = getField(req.params, 'roi', []);
        method = getField(req.params, 'method', 'otsu');
        options = req.params;
        [fullMask, roiMask, bbox] = segmentMotif(img, roi, method, options);
        imwrite(fullMask, outputPath);
        metrics.bbox = bbox;

      case {'refineMotifMask', 'refine_motif_mask'}
        maskImg = imread(req.inputPath);
        ops = getField(req.params, 'operations', {'fill_holes', 'remove_noise', 'smooth'});
        outImg = refineMotifMask(maskImg, ops, req.params);
        imwrite(outImg, outputPath);

      case {'extractTransparentMotif', 'motif_extraction', 'extract_motif'}
        sourceImg = imread(req.inputPath);
        maskImg = imread(req.inputMaskPath);
        [cropRGB, cropAlpha, bbox] = motif_extraction(sourceImg, maskImg, outputPath, req.params);
        metrics.bbox = bbox;
        metrics.width = size(cropRGB, 2);
        metrics.height = size(cropRGB, 1);

      case {'composeMotif', 'motif_compositing', 'compose_motif'}
        destImg = imread(req.destPath);
        [motifImg, ~, alphaChannel] = imread(req.inputPath);
        if isempty(alphaChannel) && size(motifImg, 3) == 4
          alphaChannel = motifImg(:, :, 4);
          motifImg = motifImg(:, :, 1:3);
        endif
        if isempty(alphaChannel) && isfield(req, 'inputMaskPath') && ~isempty(req.inputMaskPath) && exist(req.inputMaskPath, 'file')
          alphaChannel = imread(req.inputMaskPath);
        endif

        posX = getField(req.params, 'posX', 1);
        posY = getField(req.params, 'posY', 1);
        scale = getField(req.params, 'scale', 1.0);
        angle = getField(req.params, 'angle', 0.0);
        opacity = getField(req.params, 'opacity', 1.0);
        flipH = getField(req.params, 'flipH', false);
        flipV = getField(req.params, 'flipV', false);

        outImg = motif_compositing(destImg, motifImg, alphaChannel, posX, posY, scale, angle, opacity, flipH, flipV, outputPath);

      otherwise
        emitError(sprintf('Unsupported algorithm requested: %s', algo));
        exit(1);
    endswitch

  catch err
    emitError(sprintf('Algorithm execution failure in "%s": %s', algo, err.message));
    exit(1);
  end_try_catch

  % Measure elapsed time
  elapsedMs = round(toc(t0) * 1000);

  % Build and emit success JSON response
  response = struct();
  response.success = true;
  response.algorithm = algo;
  response.executionTimeMs = elapsedMs;
  response.outputPath = outputPath;

  if exist('outImg', 'var')
    response.imageInfo = struct('height', size(outImg, 1), 'width', size(outImg, 2), 'channels', size(outImg, 3));
  endif
  response.metrics = metrics;

  emitSuccess(response);
  exit(0);

endfunction

% --- Helper Functions ---

function val = getField(s, fieldName, defaultVal)
  if isfield(s, fieldName) && ~isempty(s.(fieldName))
    val = s.(fieldName);
  else
    val = defaultVal;
  endif
endfunction

function emitError(errMsg)
  resp = struct('success', false, 'error', errMsg);
  fprintf('\nOCTAVE_JSON_START\n');
  try
    disp(jsonencode(resp));
  catch
    fprintf('{"success": false, "error": "%s"}\n', errMsg);
  end_try_catch
  fprintf('OCTAVE_JSON_END\n');
  fflush(stdout);
endfunction

function emitSuccess(s)
  fprintf('\nOCTAVE_JSON_START\n');
  try
    disp(jsonencode(s));
  catch
    fprintf('{"success": true, "algorithm": "%s"}\n', s.algorithm);
  end_try_catch
  fprintf('OCTAVE_JSON_END\n');
  fflush(stdout);
endfunction
