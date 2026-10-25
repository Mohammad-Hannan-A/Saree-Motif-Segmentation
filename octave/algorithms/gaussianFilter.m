function [filteredImg] = gaussianFilter(inputImg, kernelSize, sigma)
% GAUSSIANFILTER Applies 2D Gaussian smoothing to reduce noise and cloth texture.
%
% Syntax:
%   filteredImg = gaussianFilter(inputImg, kernelSize, sigma)
%
% Inputs:
%   inputImg   - Grayscale or RGB image (uint8 or double).
%   kernelSize - (Optional) Odd integer specifying kernel dimensions [K x K]. Default is 5.
%   sigma      - (Optional) Standard deviation of the Gaussian distribution. Default is 1.5.
%
% Outputs:
%   filteredImg - Noise-reduced image matching the input data type and channels.
%
% Theory:
%   The 2D Gaussian kernel is defined as:
%     G(x, y) = (1 / (2 * pi * sigma^2)) * exp(-(x^2 + y^2) / (2 * sigma^2))
%   Gaussian filtering acts as a low-pass filter, attenuating high-frequency noise
%   while preserving larger structural edges of motifs.

  if nargin < 1 || isempty(inputImg)
    error('gaussianFilter: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(kernelSize)
    kernelSize = 5;
  endif

  if nargin < 3 || isempty(sigma)
    sigma = 1.5;
  endif

  kernelSize = max(3, round(kernelSize));
  if mod(kernelSize, 2) == 0
    kernelSize = kernelSize + 1;
  endif

  % Generate 2D Gaussian Kernel
  halfSize = floor(kernelSize / 2);
  [X, Y] = meshgrid(-halfSize:halfSize, -halfSize:halfSize);
  kernel = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
  kernel = kernel / sum(kernel(:)); % Normalize kernel sum to 1

  % Process per channel
  [rows, cols, channels] = size(inputImg);
  imgDouble = double(inputImg);
  filteredDouble = zeros(rows, cols, channels);

  for c = 1:channels
    filteredDouble(:, :, c) = conv2(imgDouble(:, :, c), kernel, 'same');
  endfor

  % Preserve input class type
  if isa(inputImg, 'uint8')
    filteredImg = uint8(max(0, min(255, round(filteredDouble))));
  elseif isa(inputImg, 'uint16')
    filteredImg = uint16(max(0, min(65535, round(filteredDouble))));
  else
    filteredImg = filteredDouble;
  endif

endfunction
