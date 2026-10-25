function [edgeImg, gradMag] = prewitt_edge_detection(inputImg, threshold)
% PREWITT_EDGE_DETECTION Computes spatial gradients using 3x3 Prewitt convolution masks.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   The Prewitt operator is a discrete differentiation operator computing an approximation
%   of the gradient of the image intensity function. Unlike Sobel (which weights center by 2),
%   Prewitt gives equal weighting (1) to all coefficients:
%     P_x = [-1  0  +1; -1  0  +1; -1  0  +1] * I
%     P_y = [+1 +1  +1;  0  0   0; -1 -1  -1] * I
%   Gradient Magnitude:
%     |G| = sqrt(P_x^2 + P_y^2)
%   Pixels with |G| >= threshold are classified as motif border edge pixels.
%
% Syntax:
%   [edgeImg, gradMag] = prewitt_edge_detection(inputImg, threshold)
%
% Inputs:
%   inputImg  - RGB or grayscale image.
%   threshold - Sensitivity threshold (default: 45, range: 10 to 200). If -1, auto-calculated.
%
% Outputs:
%   edgeImg   - Binary edge map (uint8: 0 or 255).
%   gradMag   - Gradient magnitude matrix.

  if nargin < 1 || isempty(inputImg)
    error('prewitt_edge_detection: Input image is required.');
  endif
  if nargin < 2 || isempty(threshold)
    threshold = 45;
  endif

  % Convert to grayscale
  if size(inputImg, 3) >= 3
    gray = 0.2989 * double(inputImg(:, :, 1)) + ...
           0.5870 * double(inputImg(:, :, 2)) + ...
           0.1140 * double(inputImg(:, :, 3));
  else
    gray = double(inputImg);
  endif

  % Prewitt convolution masks
  Px = [-1, 0, 1; -1, 0, 1; -1, 0, 1];
  Py = [1, 1, 1; 0, 0, 0; -1, -1, -1];

  padded = padarray(gray, [1, 1], 'replicate');
  Gx = conv2(padded, Px, 'valid');
  Gy = conv2(padded, Py, 'valid');

  gradMag = sqrt(Gx.^2 + Gy.^2);

  if threshold < 0
    threshold = mean(gradMag(:)) + std(gradMag(:));
  endif

  edgeImg = uint8((gradMag >= threshold) * 255);

endfunction
