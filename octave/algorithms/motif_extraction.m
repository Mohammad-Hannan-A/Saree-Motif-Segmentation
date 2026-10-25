function [croppedRGB, croppedAlpha, bbox, refinedMask] = motif_extraction(sourceImg, maskImg, outputPath, options)
% MOTIF_EXTRACTION Extracts decorative saree motif with refined boundary and transparent background PNG.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Digital motif extraction isolates decorative zari/embroidery patterns from the silk background.
%   1. Mask Refinement: Cleans raw threshold or color segmentation masks via mathematical morphology:
%      - Morphological hole filling: imfill(mask, 'holes') to seal hollow gaps inside motifs.
%      - Noise removal: area filtering (bwareaopen) or opening to remove isolated background yarn specks.
%      - Boundary smoothing: closing with disk structuring element.
%   2. Alpha Channel Matting:
%      The refined binary mask defines an 8-bit Alpha matte A(x, y) \in [0, 255]:
%        A(x, y) = 255 for motif pixels (fully opaque)
%        A(x, y) = 0   for background fabric (100% transparent)
%   3. Bounding Box Cropping:
%      Crops the extracted motif tightly to its bounding box plus user padding.
%   4. Genuine 32-bit RGBA PNG Export:
%      imwrite(croppedRGB, outputPath, 'Alpha', croppedAlpha);
%
% Syntax:
%   [croppedRGB, croppedAlpha, bbox, refinedMask] = motif_extraction(sourceImg, maskImg, outputPath, options)
%
% Inputs:
%   sourceImg  - RGB saree image [M x N x 3].
%   maskImg    - Binary mask [M x N] from color/threshold/region/bounding box segmentation.
%   outputPath - Output filename/path for the transparent PNG.
%   options    - Struct with optional fields:
%                options.padding (default: 5)
%                options.fillHoles (default: true)
%                options.cleanNoise (default: true)
%                options.minArea (default: 20)

  if nargin < 2 || isempty(sourceImg) || isempty(maskImg)
    error('motif_extraction: Source image and mask are required.');
  endif
  if nargin < 3, outputPath = ''; endif
  if nargin < 4 || isempty(options), options = struct(); endif

  padding = 5;
  if isfield(options, 'padding') && ~isempty(options.padding)
    padding = round(options.padding);
  endif

  fillHoles = true;
  if isfield(options, 'fillHoles')
    fillHoles = Boolean(options.fillHoles);
  endif

  cleanNoise = true;
  if isfield(options, 'cleanNoise')
    cleanNoise = Boolean(options.cleanNoise);
  endif

  % Prepare binary mask
  rawMask = (maskImg > 0);
  refinedMask = rawMask;

  % 1. Morphological hole filling
  if fillHoles
    try
      refinedMask = imfill(refinedMask, 'holes');
    catch
      % Fallback closing
      seHole = strel('disk', 3);
      refinedMask = imclose(refinedMask, seHole);
    end_try_catch
  endif

  % 2. Noise speckle removal
  if cleanNoise
    try
      minArea = 25;
      if isfield(options, 'minArea'), minArea = round(options.minArea); endif
      refinedMask = bwareaopen(refinedMask, minArea);
    catch
      % Fallback opening
      seNoise = strel('disk', 1);
      refinedMask = imopen(refinedMask, seNoise);
    end_try_catch
  endif

  % 3. Extract tight bounding box around foreground mask
  [rows, cols] = find(refinedMask);

  [H, W, channels] = size(sourceImg);
  if channels == 1
    rgb = repmat(uint8(sourceImg), [1, 1, 3]);
  else
    rgb = uint8(sourceImg(:, :, 1:3));
  endif

  if isempty(rows)
    warning('motif_extraction: Mask has no foreground pixels. Creating 1x1 transparent image.');
    croppedRGB = zeros(1, 1, 3, 'uint8');
    croppedAlpha = zeros(1, 1, 'uint8');
    bbox = [1, 1, 1, 1];
    if ~isempty(outputPath)
      imwrite(croppedRGB, outputPath, 'Alpha', croppedAlpha);
    endif
    return;
  endif

  minY = max(1, min(rows) - padding);
  maxY = min(H, max(rows) + padding);
  minX = max(1, min(cols) - padding);
  maxX = min(W, max(cols) + padding);

  bbox = [minX, minY, (maxX - minX + 1), (maxY - minY + 1)];

  % 4. Crop RGB and Alpha matrices
  croppedRGB = rgb(minY:maxY, minX:maxX, :);
  croppedAlpha = uint8(refinedMask(minY:maxY, minX:maxX) * 255);

  % 5. Save 32-bit transparent PNG if outputPath is specified
  if ~isempty(outputPath)
    outDir = fileparts(outputPath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
      mkdir(outDir);
    endif
    imwrite(croppedRGB, outputPath, 'Alpha', croppedAlpha);
  endif

endfunction
