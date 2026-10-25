function [compositeImg] = composeMotif(destImg, motifRGB, motifAlpha, posX, posY, scale, angle, opacity, flipH, flipV, outputFilePath)
% COMPOSEMOTIF Seamlessly blends an extracted decorative motif onto a destination clothing garment.
%
% Syntax:
%   compositeImg = composeMotif(destImg, motifRGB, motifAlpha, posX, posY, scale, angle, opacity, flipH, flipV, outputFilePath)
%
% Inputs:
%   destImg        - Destination clothing image matrix [M x N x 3] (RGB uint8).
%   motifRGB       - Extracted motif RGB matrix [m x n x 3] (uint8).
%   motifAlpha     - Extracted motif Alpha matrix [m x n] (uint8: 0=transparent, 255=opaque).
%   posX           - Horizontal X coordinate (column) on destination image for motif top-left.
%   posY           - Vertical Y coordinate (row) on destination image for motif top-left.
%   scale          - (Optional) Scaling factor (e.g., 1.0 = 100%, 0.5 = 50%, 1.5 = 150%). Default is 1.0.
%   angle          - (Optional) Rotation angle in degrees (counter-clockwise). Default is 0.
%   opacity        - (Optional) Blending opacity in [0.0, 1.0]. Default is 1.0.
%   flipH          - (Optional) Boolean flag to flip motif horizontally. Default is false.
%   flipV          - (Optional) Boolean flag to flip motif vertically. Default is false.
%   outputFilePath - (Optional) Destination file path to save the final composite image.
%
% Outputs:
%   compositeImg   - Final composite image with identical dimensions to destImg.
%
% Theory & Alpha Compositing:
%   Compositing adheres to the Porter-Duff 'Over' blending operator:
%     C_out(x, y) = C_dest(x, y) * (1 - Alpha_eff(x, y)) + C_motif(x, y) * Alpha_eff(x, y)
%   where Alpha_eff(x, y) = (Alpha_motif(x, y) / 255) * opacity.
%   Handles boundary clipping, arbitrary rotation, scaling, and geometric reflection
%   entirely within GNU Octave without relying on client-side browser canvas shortcuts.

  if nargin < 5
    error('composeMotif: InvalidInput, destination image, motif RGB, alpha, posX, and posY are required.');
  endif

  if nargin < 6 || isempty(scale), scale = 1.0; endif
  if nargin < 7 || isempty(angle), angle = 0.0; endif
  if nargin < 8 || isempty(opacity), opacity = 1.0; endif
  if nargin < 9 || isempty(flipH), flipH = false; endif
  if nargin < 10 || isempty(flipV), flipV = false; endif
  if nargin < 11, outputFilePath = ''; endif

  % Ensure Octave image package is available
  if ~exist('imresize', 'file') && ~exist('imresize', 'builtin')
    pkg load image;
  endif

  % Validate destination image dimensions
  if size(destImg, 3) < 3
    destRGB = repmat(uint8(destImg), [1, 1, 3]);
  else
    destRGB = uint8(destImg(:, :, 1:3));
  endif
  [dstH, dstW, ~] = size(destRGB);

  % Validate motif RGB and Alpha
  currRGB = uint8(motifRGB);
  if isempty(motifAlpha)
    currAlpha = 255 * ones(size(currRGB, 1), size(currRGB, 2), 'uint8');
  else
    currAlpha = uint8(motifAlpha);
  endif

  % 1. Horizontal and Vertical Flipping
  if flipH
    for c = 1:size(currRGB, 3)
      currRGB(:, :, c) = fliplr(currRGB(:, :, c));
    endfor
    currAlpha = fliplr(currAlpha);
  endif

  if flipV
    for c = 1:size(currRGB, 3)
      currRGB(:, :, c) = flipud(currRGB(:, :, c));
    endfor
    currAlpha = flipud(currAlpha);
  endif

  % 2. Resizing
  scale = max(0.05, min(10.0, scale));
  if abs(scale - 1.0) > 0.001
    currRGB = imresize(currRGB, scale, 'bilinear');
    currAlpha = imresize(currAlpha, scale, 'bilinear');
  endif

  % 3. Rotation
  if abs(angle) > 0.001
    currRGB = imrotate(currRGB, angle, 'bilinear', 'loose');
    currAlpha = imrotate(currAlpha, angle, 'bilinear', 'loose');
  endif

  [motifH, motifW, ~] = size(currRGB);

  % 4. Coordinate Clamping & Boundary Clipping
  % User supplies (posX, posY) as 1-based coordinates
  px = round(posX);
  py = round(posY);

  % Compute intersection between motif rectangle and destination canvas
  dstX1 = max(1, px);
  dstY1 = max(1, py);
  dstX2 = min(dstW, px + motifW - 1);
  dstY2 = min(dstH, py + motifH - 1);

  % Check if motif is completely out of destination boundaries
  if dstX1 > dstW || dstX2 < 1 || dstY1 > dstH || dstY2 < 1
    warning('composeMotif: Motif is positioned entirely outside the destination image boundaries.');
    compositeImg = destRGB;
    if ~isempty(outputFilePath)
      imwrite(compositeImg, outputFilePath);
    endif
    return;
  endif

  % Corresponding source sub-region inside transformed motif
  srcX1 = 1 + (dstX1 - px);
  srcY1 = 1 + (dstY1 - py);
  srcX2 = srcX1 + (dstX2 - dstX1);
  srcY2 = srcY1 + (dstY2 - dstY1);

  % Extract overlapping regions
  overlapDst = double(destRGB(dstY1:dstY2, dstX1:dstX2, :));
  overlapMotif = double(currRGB(srcY1:srcY2, srcX1:srcX2, :));
  overlapAlpha = double(currAlpha(srcY1:srcY2, srcX1:srcX2)) / 255.0;

  % Apply user opacity
  opacity = max(0.0, min(1.0, opacity));
  effectiveAlpha = overlapAlpha * opacity;

  % Alpha Blending
  blendedRegion = zeros(size(overlapDst));
  for c = 1:3
    blendedRegion(:, :, c) = overlapDst(:, :, c) .* (1.0 - effectiveAlpha) + ...
                             overlapMotif(:, :, c) .* effectiveAlpha;
  endfor

  % Construct final composite
  compositeImg = destRGB;
  compositeImg(dstY1:dstY2, dstX1:dstX2, :) = uint8(round(blendedRegion));

  % Save composite image if output path specified
  if ~isempty(outputFilePath)
    [outDir, ~, ~] = fileparts(outputFilePath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
      mkdir(outDir);
    endif
    imwrite(compositeImg, outputFilePath);
  endif

endfunction
