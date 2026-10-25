function [fullMask, roiMask, bbox] = segmentMotif(inputImg, roi, method, options)
% SEGMENTMOTIF Segments a targeted decorative saree motif within a region of interest.
%
% Syntax:
%   [fullMask, roiMask, bbox] = segmentMotif(inputImg, roi, method, options)
%
% Inputs:
%   inputImg - RGB or grayscale saree image [Rows x Cols x Channels].
%   roi      - 4-element vector [x, y, width, height] defining the bounding box.
%              (x = horizontal column, y = vertical row).
%              If empty or [0 0 0 0], the entire image is processed.
%   method   - (Optional) String specifying segmentation algorithm:
%              'otsu'     - Otsu's optimal global binarization (default)
%              'adaptive' - Local window adaptive thresholding
%              'color'    - Color distance segmentation
%              'edge'     - Edge-based morphological enclosing
%   options  - (Optional) Struct of algorithm-specific parameters:
%              .threshold    - Threshold value or offset
%              .invert       - Boolean to invert foreground/background
%              .targetColor  - [R G B] target color for 'color' method
%              .tolerance    - Color distance tolerance
%              .windowSize   - Window size for 'adaptive' method
%              .minArea      - Minimum connected component pixel area to retain
%              .keepLargest  - Boolean: if true, only keep the dominant connected motif
%
% Outputs:
%   fullMask - Binary mask of full image dimensions [Rows x Cols] (uint8: 0 or 255).
%   roiMask  - Binary mask cropped strictly to the ROI dimensions.
%   bbox     - Validated integer bounding box [xMin, yMin, width, height].

  if nargin < 1 || isempty(inputImg)
    error('segmentMotif: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(roi)
    roi = [];
  endif

  if nargin < 3 || isempty(method)
    method = 'otsu';
  endif

  if nargin < 4 || isempty(options)
    options = struct();
  endif

  % Extract options with safe defaults
  optInvert = isfield(options, 'invert') && options.invert;
  optThresh = -1;
  if isfield(options, 'threshold') && ~isempty(options.threshold)
    optThresh = options.threshold;
  endif
  optWindowSize = 25;
  if isfield(options, 'windowSize') && ~isempty(options.windowSize)
    optWindowSize = options.windowSize;
  endif
  optTargetColor = [218, 165, 32]; % Default gold zari
  if isfield(options, 'targetColor') && ~isempty(options.targetColor)
    optTargetColor = options.targetColor;
  endif
  optTolerance = 50.0;
  if isfield(options, 'tolerance') && ~isempty(options.tolerance)
    optTolerance = options.tolerance;
  endif
  optMinArea = 50;
  if isfield(options, 'minArea') && ~isempty(options.minArea)
    optMinArea = options.minArea;
  endif
  optKeepLargest = false;
  if isfield(options, 'keepLargest')
    optKeepLargest = options.keepLargest;
  endif

  [imgRows, imgCols, channels] = size(inputImg);

  % Validate and clamp ROI coordinates
  if isempty(roi) || numel(roi) < 4 || (roi(3) <= 0 || roi(4) <= 0)
    xMin = 1;
    yMin = 1;
    xMax = imgCols;
    yMax = imgRows;
  else
    % Convert to 1-based indexing if 0-based
    rx = round(roi(1));
    ry = round(roi(2));
    rw = round(roi(3));
    rh = round(roi(4));

    if rx <= 0, rx = 1; endif
    if ry <= 0, ry = 1; endif

    xMin = max(1, min(imgCols, rx));
    yMin = max(1, min(imgRows, ry));
    xMax = max(xMin, min(imgCols, xMin + rw - 1));
    yMax = max(yMin, min(imgRows, yMin + rh - 1));
  endif

  bbox = [xMin, yMin, (xMax - xMin + 1), (yMax - yMin + 1)];

  % Crop the region of interest
  roiImg = inputImg(yMin:yMax, xMin:xMax, :);

  % Segment the cropped ROI
  switch lower(method)
    case 'adaptive'
      rawRoiMask = adaptiveThreshold(roiImg, optWindowSize, 5, optInvert);

    case 'color'
      if channels >= 3
        [rawRoiMask, ~] = colorSegmentation(roiImg, optTargetColor, optTolerance, 'RGB');
        if optInvert
          rawRoiMask = 255 - rawRoiMask;
        endif
      else
        rawRoiMask = binaryThreshold(roiImg, optThresh, optInvert);
      endif

    case 'edge'
      edges = cannyEdgeDetection(roiImg);
      % Close edges and fill interior
      if ~exist('imfill', 'file') && ~exist('imfill', 'builtin')
        pkg load image;
      endif
      se = strel('disk', 3);
      closedEdges = imclose(edges > 0, se);
      filled = imfill(closedEdges, 'holes');
      rawRoiMask = uint8(filled * 255);
      if optInvert
        rawRoiMask = 255 - rawRoiMask;
      endif

    case 'otsu'
      rawRoiMask = binaryThreshold(roiImg, optThresh, optInvert);

    otherwise
      rawRoiMask = binaryThreshold(roiImg, optThresh, optInvert);
  endswitch

  % Perform connected-component analysis to filter noise
  if ~exist('bwlabel', 'file') && ~exist('bwlabel', 'builtin')
    pkg load image;
  endif

  logicalRoi = (rawRoiMask > 0);
  [labeled, numLabels] = bwlabel(logicalRoi);

  if numLabels > 0
    props = regionprops(labeled, 'Area');
    areas = [props.Area];

    if optKeepLargest
      [~, maxIdx] = max(areas);
      cleanLogical = (labeled == maxIdx);
    else
      % Remove components smaller than minimum area
      validLabels = find(areas >= optMinArea);
      cleanLogical = ismember(labeled, validLabels);
    endif
    roiMask = uint8(cleanLogical * 255);
  else
    roiMask = rawRoiMask;
  endif

  % Embed the ROI mask back into the full-size image mask
  fullMask = zeros(imgRows, imgCols, 'uint8');
  fullMask(yMin:yMax, xMin:xMax) = roiMask;

endfunction
