function [filteredImg] = gaussian_filtering(inputImg, kernelSize, sigma)
% GAUSSIAN_FILTERING Smooths an image using a 2D Gaussian convolution kernel.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Gaussian smoothing acts as an isotropic 2D low-pass spatial filter:
%     G(x, y) = (1 / (2 * pi * sigma^2)) * exp(-(x^2 + y^2) / (2 * sigma^2))
%   It attenuates high-frequency sensor noise, yarn grain texture, and weave irregularities
%   before edge detection or motif boundary extraction, preventing spurious broken edges.
%
% Syntax:
%   filteredImg = gaussian_filtering(inputImg, kernelSize, sigma)
%
% Inputs:
%   inputImg   - RGB or grayscale image.
%   kernelSize - Odd integer (e.g., 3, 5, 7, 9). Default: 5.
%   sigma      - Standard deviation of Gaussian distribution (e.g., 1.5). Default: 1.5.
%
% Outputs:
%   filteredImg - Smoothed image with noise reduced.

  if nargin < 1 || isempty(inputImg)
    error('gaussian_filtering: Input image is required.');
  endif
  if nargin < 2 || isempty(kernelSize) || kernelSize < 1
    kernelSize = 5;
  endif
  if nargin < 3 || isempty(sigma) || sigma <= 0
    sigma = 1.5;
  endif

  % Ensure kernel size is an odd integer
  kernelSize = round(kernelSize);
  if mod(kernelSize, 2) == 0
    kernelSize = kernelSize + 1;
  endif

  % Generate 2D Gaussian kernel analytically
  radius = floor(kernelSize / 2);
  [x, y] = meshgrid(-radius:radius, -radius:radius);
  kernel = exp(-(x.^2 + y.^2) / (2 * sigma^2));
  kernel = kernel / sum(kernel(:)); % Normalize kernel coefficients to sum to 1.0

  % Perform 2D convolution channel-by-channel
  [rows, cols, channels] = size(inputImg);
  filteredImg = zeros(rows, cols, channels, class(inputImg));

  for c = 1:channels
    plane = double(inputImg(:, :, c));
    % Symmetric replicate border padding to prevent dark perimeter borders
    padded = padarray(plane, [radius, radius], 'replicate');
    convResult = conv2(padded, kernel, 'valid');

    if isinteger(inputImg)
      filteredImg(:, :, c) = cast(round(convResult), class(inputImg));
    else
      filteredImg(:, :, c) = convResult;
    endif
  endfor

endfunction
