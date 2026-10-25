function [binMask] = binaryThreshold(inputImg, threshold, invert)
% BINARYTHRESHOLD Segments an image into foreground and background using a global threshold.
%
% Syntax:
%   binMask = binaryThreshold(inputImg, threshold, invert)
%
% Inputs:
%   inputImg  - Grayscale or RGB image. If RGB, it is automatically converted to grayscale.
%   threshold - (Optional) Cutoff value in [0, 255] or [0, 1].
%               If omitted or -1, Otsu's method (graythresh) is used to find the optimal threshold.
%   invert    - (Optional) Boolean flag. If true, foreground pixels are those <= threshold.
%               Default is false (foreground is > threshold).
%
% Outputs:
%   binMask   - Binary mask as uint8 (0 for background, 255 for foreground) or logical.
%
% Purpose:
%   Global thresholding separates high-contrast motifs (e.g., golden zari or bright threadwork)
%   from dark silk saree fabrics by choosing a global intensity divider.

  if nargin < 1 || isempty(inputImg)
    error('binaryThreshold: InvalidInput, input image is required.');
  endif

  if nargin < 2
    threshold = -1; % Signal to use automatic Otsu threshold
  endif

  if nargin < 3
    invert = false;
  endif

  % Convert to grayscale if RGB
  if size(inputImg, 3) >= 3
    gray = grayscale(inputImg);
  else
    gray = inputImg;
  endif

  % Convert to double for consistent calculation
  grayDouble = double(gray);
  maxVal = max(grayDouble(:));
  if maxVal <= 1.0 && min(grayDouble(:)) >= 0.0 && ~isa(gray, 'uint8')
    % Normalized [0, 1] range
    grayNorm = grayDouble;
  else
    grayNorm = grayDouble / 255.0;
  endif

  % Determine threshold value
  if threshold < 0
    % Otsu's optimal global threshold
    if exist('graythresh', 'file') || exist('graythresh', 'builtin')
      t = graythresh(grayNorm);
    else
      % Fallback Otsu implementation
      t = graythresh_internal(grayNorm);
    endif
  else
    if threshold > 1.0
      t = threshold / 255.0;
    else
      t = threshold;
    endif
  endif

  % Perform thresholding
  if invert
    logicalMask = (grayNorm <= t);
  else
    logicalMask = (grayNorm > t);
  endif

  % Return as uint8 (0 or 255) for standard image compatibility
  binMask = uint8(logicalMask * 255);

endfunction

% Helper function for Otsu calculation in case image package is not loaded
function t = graythresh_internal(imgNorm)
  counts = hist(imgNorm(:), linspace(0, 1, 256));
  p = counts / sum(counts);
  omega = cumsum(p);
  mu = cumsum(p .* (1:256));
  mu_t = mu(end);

  sigma_b_squared = (mu_t * omega - mu).^2 ./ (omega .* (1 - omega) + eps);
  [maxval, idx] = max(sigma_b_squared);
  t = (idx - 1) / 255.0;
endfunction
