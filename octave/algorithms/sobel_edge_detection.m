function [edgeImg, gradMag, gradDir] = sobel_edge_detection(inputImg, threshold)
% SOBEL_EDGE_DETECTION Computes spatial intensity gradients using 3x3 Sobel convolution operators.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   The Sobel operator estimates spatial derivatives in horizontal (x) and vertical (y) directions:
%     G_x = [-1  0  +1; -2  0  +2; -1  0  +1] * I
%     G_y = [+1 +2  +1;  0  0   0; -1 -2  -1] * I
%   The weight of 2 at the center gives smoothing, making Sobel less sensitive to noise than simple differencing.
%   Gradient Magnitude:
%     |G| = sqrt(G_x^2 + G_y^2)
%   Pixels with |G| >= threshold are classified as edge pixels.
%
% Syntax:
%   [edgeImg, gradMag, gradDir] = sobel_edge_detection(inputImg, threshold)
%
% Inputs:
%   inputImg  - RGB or grayscale image.
%   threshold - Sensitivity threshold (default: 50, range: 10 to 200). If -1, auto-calculated.
%
% Outputs:
%   edgeImg   - Binary edge map (uint8: 0 or 255).
%   gradMag   - Normalized gradient magnitude matrix [0, 255].
%   gradDir   - Gradient direction angle in radians [-pi, pi].

  if nargin < 1 || isempty(inputImg)
    error('sobel_edge_detection: Input image is required.');
  endif
  if nargin < 2 || isempty(threshold)
    threshold = 50;
  endif

  % Convert to grayscale
  if size(inputImg, 3) >= 3
    gray = 0.2989 * double(inputImg(:, :, 1)) + ...
           0.5870 * double(inputImg(:, :, 2)) + ...
           0.1140 * double(inputImg(:, :, 3));
  else
    gray = double(inputImg);
  endif

  % Sobel convolution kernels
  Sx = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
  Sy = [1, 2, 1; 0, 0, 0; -1, -2, -1];

  % 2D Convolution with replicate border
  padded = padarray(gray, [1, 1], 'replicate');
  Gx = conv2(padded, Sx, 'valid');
  Gy = conv2(padded, Sy, 'valid');

  gradMag = sqrt(Gx.^2 + Gy.^2);
  gradDir = atan2(Gy, Gx);

  if threshold < 0
    threshold = mean(gradMag(:)) + std(gradMag(:));
  endif

  edgeImg = uint8((gradMag >= threshold) * 255);

endfunction
