function [contourMap, overlayImg] = contourDetection(inputImg, thickness)
% CONTOURDETECTION Extracts the outer boundary contours of segmented saree motifs.
%
% Syntax:
%   [contourMap, overlayImg] = contourDetection(inputImg, thickness)
%
% Inputs:
%   inputImg  - Binary mask or grayscale/RGB image.
%   thickness - (Optional) Integer contour line width (1, 2, or 3). Default is 1.
%
% Outputs:
%   contourMap - Binary image (uint8, 0 or 255) showing 1-pixel or thick motif outlines.
%   overlayImg - RGB image showing contours highlighted (e.g. vibrant cyan/green) over original image.
%
% Theory:
%   Morphological internal boundary extraction is formulated as:
%     Beta(A) = A - (A (-) B)
%   where A is the binary motif mask and B is a 3x3 structuring element.
%   The difference between the original foreground and its eroded version isolates
%   the exact 1-pixel perimeter enclosing the decorative motif.

  if nargin < 1 || isempty(inputImg)
    error('contourDetection: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(thickness)
    thickness = 1;
  endif

  % Check if input is RGB, grayscale, or binary
  if size(inputImg, 3) >= 3
    origRGB = uint8(inputImg(:, :, 1:3));
    binMask = binaryThreshold(origRGB, -1); % Otsu binarization
  elseif max(inputImg(:)) > 1 && ~islogical(inputImg)
    origRGB = repmat(uint8(inputImg), [1, 1, 3]);
    binMask = binaryThreshold(inputImg, -1);
  else
    binMask = uint8(inputImg > 0) * 255;
    origRGB = repmat(binMask, [1, 1, 3]);
  endif

  % Ensure Octave image package is loaded
  if ~exist('imerode', 'file') && ~exist('imerode', 'builtin')
    pkg load image;
  endif

  % Morphological boundary extraction
  se = strel('square', 2 * thickness + 1);
  eroded = imerode(binMask, se);
  contourMap = binMask - eroded;

  % Generate visual overlay: Motif boundaries drawn in bright green [0, 255, 0]
  overlayImg = origRGB;
  contourIdx = (contourMap > 0);

  rCh = overlayImg(:, :, 1);
  gCh = overlayImg(:, :, 2);
  bCh = overlayImg(:, :, 3);

  rCh(contourIdx) = 0;
  gCh(contourIdx) = 255;
  bCh(contourIdx) = 0;

  overlayImg(:, :, 1) = rCh;
  overlayImg(:, :, 2) = gCh;
  overlayImg(:, :, 3) = bCh;

endfunction
