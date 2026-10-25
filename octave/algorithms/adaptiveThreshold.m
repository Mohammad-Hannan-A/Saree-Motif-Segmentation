function [binMask] = adaptiveThreshold(inputImg, windowSize, constantC, invert)
% ADAPTIVETHRESHOLD Performs local adaptive thresholding on an image.
%
% Syntax:
%   binMask = adaptiveThreshold(inputImg, windowSize, constantC, invert)
%
% Inputs:
%   inputImg   - Grayscale or RGB image.
%   windowSize - (Optional) Odd integer for local neighborhood size (e.g., 15, 25, 51). Default is 25.
%   constantC  - (Optional) Offset subtracted from the local neighborhood mean. Default is 5.
%   invert     - (Optional) Boolean flag. If true, inverts foreground and background. Default is false.
%
% Outputs:
%   binMask    - Binary mask as uint8 (0 or 255).
%
% Theoretical Explanation (Global vs. Local Thresholding):
%   - Global Thresholding applies a single intensity threshold across the entire image.
%     It works well only under uniform lighting with high contrast between motif and background.
%   - Local/Adaptive Thresholding calculates a unique threshold for each pixel based on
%     the mean intensity in its local neighborhood (W x W window):
%         T(x, y) = LocalMean(x, y) - C
%     This makes it robust against uneven fabric folds, cloth shadows, and non-uniform lighting
%     common in photographed clothing and sarees.
%
% Compatibility:
%   Implemented using standard 2D spatial convolution (conv2) with symmetric padding
%   to ensure full compatibility with GNU Octave without requiring proprietary MATLAB toolboxes.

  if nargin < 1 || isempty(inputImg)
    error('adaptiveThreshold: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(windowSize)
    windowSize = 25;
  endif

  if nargin < 3 || isempty(constantC)
    constantC = 5;
  endif

  if nargin < 4 || isempty(invert)
    invert = false;
  endif

  % Ensure window size is an odd integer >= 3
  windowSize = max(3, round(windowSize));
  if mod(windowSize, 2) == 0
    windowSize = windowSize + 1;
  endif

  % Convert RGB to Grayscale
  if size(inputImg, 3) >= 3
    gray = grayscale(inputImg);
  else
    gray = inputImg;
  endif

  grayDouble = double(gray);

  % Create averaging kernel for the local neighborhood
  kernel = ones(windowSize, windowSize) / (windowSize * windowSize);

  % Pad image boundaries to avoid edge artifacts (replicate border pixels)
  padRadius = floor(windowSize / 2);
  paddedImg = padarray_replicate(grayDouble, [padRadius, padRadius]);

  % Compute local mean using 2D convolution
  localMean = conv2(paddedImg, kernel, 'valid');

  % Calculate adaptive threshold: T(x, y) = localMean(x, y) - constantC
  thresholdMap = localMean - constantC;

  % Threshold the image
  if invert
    logicalMask = (grayDouble <= thresholdMap);
  else
    logicalMask = (grayDouble > thresholdMap);
  endif

  binMask = uint8(logicalMask * 255);

endfunction

% Helper function for border replication padding (compatible with GNU Octave core)
function padded = padarray_replicate(img, padSizes)
  rPad = padSizes(1);
  cPad = padSizes(2);
  [R, C] = size(img);

  % Replicate top and bottom rows
  topRows = repmat(img(1, :), rPad, 1);
  botRows = repmat(img(end, :), rPad, 1);
  vertical = [topRows; img; botRows];

  % Replicate left and right columns
  leftCols = repmat(vertical(:, 1), 1, cPad);
  rightCols = repmat(vertical(:, end), 1, cPad);
  padded = [leftCols, vertical, rightCols];
endfunction
