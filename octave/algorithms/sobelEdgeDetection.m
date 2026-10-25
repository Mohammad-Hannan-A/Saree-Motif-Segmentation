function [edgeMap, gradMag, gradDir] = sobelEdgeDetection(inputImg, threshold)
% SOBELEDGEDETECTION Computes spatial gradients using 3x3 Sobel convolution operators.
%
% Syntax:
%   [edgeMap, gradMag, gradDir] = sobelEdgeDetection(inputImg, threshold)
%
% Inputs:
%   inputImg  - Grayscale or RGB image.
%   threshold - (Optional) Intensity threshold for binarizing edges [0 to 255].
%               If empty or <= 0, returns the continuous normalized gradient magnitude.
%
% Outputs:
%   edgeMap   - Binary edge map (uint8, 0 or 255) if threshold > 0, or gradient magnitude image.
%   gradMag   - Floating point gradient magnitude matrix.
%   gradDir   - Floating point gradient angle in radians [-pi, pi].
%
% Theory:
%   Sobel masks perform discrete differentiation with Gaussian smoothing:
%     Gx = [-1 0 1; -2 0 2; -1 0 1] (horizontal gradient)
%     Gy = [-1 -2 -1; 0 0 0; 1 2 1] (vertical gradient)
%   Magnitude: M(x, y) = sqrt(Gx^2 + Gy^2)
%   Direction: Theta(x, y) = atan2(Gy, Gx)

  if nargin < 1 || isempty(inputImg)
    error('sobelEdgeDetection: InvalidInput, input image is required.');
  endif

  if nargin < 2
    threshold = 50; % Default edge cutoff
  endif

  % Convert to grayscale
  if size(inputImg, 3) >= 3
    gray = grayscale(inputImg);
  else
    gray = inputImg;
  endif

  grayDouble = double(gray);

  % 3x3 Sobel Kernels
  GxKernel = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
  GyKernel = [-1, -2, -1; 0, 0, 0; 1, 2, 1];

  % Compute directional gradients via 2D convolution
  Gx = conv2(grayDouble, GxKernel, 'same');
  Gy = conv2(grayDouble, GyKernel, 'same');

  % Calculate magnitude and orientation
  gradMag = sqrt(Gx.^2 + Gy.^2);
  gradDir = atan2(Gy, Gx);

  if threshold > 0
    % Binarize edges at threshold
    edgeMap = uint8((gradMag >= threshold) * 255);
  else
    % Normalize gradient magnitude to [0, 255]
    maxMag = max(gradMag(:));
    if maxMag > 0
      normMag = (gradMag / maxMag) * 255.0;
    else
      normMag = gradMag;
    endif
    edgeMap = uint8(round(normMag));
  endif

endfunction
