function [croppedRGB, croppedAlpha, bbox] = extractTransparentMotif(sourceImg, binaryMask, outputFilePath, padding)
% EXTRACTTRANSPARENTMOTIF Extracts a segmented motif, crops to its bounding box,
% and exports a genuine 32-bit RGBA PNG with alpha channel transparency.
%
% Syntax:
%   [croppedRGB, croppedAlpha, bbox] = extractTransparentMotif(sourceImg, binaryMask, outputFilePath, padding)
%
% Inputs:
%   sourceImg      - Original RGB saree image [M x N x 3].
%   binaryMask     - Binary motif mask [M x N] (0 = background, >0 = motif).
%   outputFilePath - (Optional) Destination file path to save the transparent PNG.
%   padding        - (Optional) Pixel border padding around the bounding box. Default is 5.
%
% Outputs:
%   croppedRGB     - Cropped RGB image containing the motif with its original colors.
%   croppedAlpha   - Cropped 8-bit Alpha channel (0 = transparent, 255 = fully opaque).
%   bbox           - Cropped bounding box coordinates [xMin, yMin, width, height].
%
% Transparency Architecture:
%   In GNU Octave, 32-bit transparent PNG files are written using the format:
%     imwrite(croppedRGB, outputFilePath, 'Alpha', croppedAlpha);
%   where 'croppedRGB' retains all authentic dye and metallic thread colors,
%   and 'croppedAlpha' acts as the 8-bit matte channel rendering the surrounding fabric
%   100% transparent.

  if nargin < 2 || isempty(sourceImg) || isempty(binaryMask)
    error('extractTransparentMotif: InvalidInput, source image and binary mask are required.');
  endif

  if nargin < 3
    outputFilePath = '';
  endif

  if nargin < 4 || isempty(padding)
    padding = 5;
  endif

  % Ensure source image is uint8 RGB
  if size(sourceImg, 3) < 3
    % Grayscale to RGB replication
    sourceRGB = repmat(uint8(sourceImg), [1, 1, 3]);
  else
    sourceRGB = uint8(sourceImg(:, :, 1:3));
  endif

  % Ensure binary mask is logical
  logicalMask = (binaryMask > 0);

  % Find non-zero mask pixels to determine the tight bounding box
  [rows, cols] = find(logicalMask);

  if isempty(rows)
    warning('extractTransparentMotif: Mask has no foreground pixels. Returning 1x1 transparent image.');
    croppedRGB = zeros(1, 1, 3, 'uint8');
    croppedAlpha = zeros(1, 1, 'uint8');
    bbox = [1, 1, 1, 1];
    if ~isempty(outputFilePath)
      imwrite(croppedRGB, outputFilePath, 'Alpha', croppedAlpha);
    endif
    return;
  endif

  [imgH, imgW, ~] = size(sourceRGB);

  % Compute bounding box with padding
  rMin = max(1, min(rows) - padding);
  rMax = min(imgH, max(rows) + padding);
  cMin = max(1, min(cols) - padding);
  cMax = min(imgW, max(cols) + padding);

  bbox = [cMin, rMin, (cMax - cMin + 1), (rMax - rMin + 1)];

  % Crop RGB image and mask
  croppedRGB = sourceRGB(rMin:rMax, cMin:cMax, :);
  croppedMask = logicalMask(rMin:rMax, cMin:cMax);

  % Create 8-bit Alpha channel (0 for transparent background, 255 for opaque motif)
  croppedAlpha = uint8(croppedMask * 255);

  % Zero-out background pixels in RGB to prevent color bleeding at anti-aliased boundaries
  for c = 1:3
    channel = croppedRGB(:, :, c);
    channel(~croppedMask) = 0;
    croppedRGB(:, :, c) = channel;
  endfor

  % Write transparent PNG if file path is specified
  if ~isempty(outputFilePath)
    % Ensure target directory exists
    [outDir, ~, ~] = fileparts(outputFilePath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
      mkdir(outDir);
    endif

    % Make sure Octave image package is available for imwrite options
    if ~exist('imwrite', 'file') && ~exist('imwrite', 'builtin')
      pkg load image;
    endif

    % Genuine Octave PNG Alpha write
    imwrite(croppedRGB, outputFilePath, 'Alpha', croppedAlpha);
  endif

endfunction
