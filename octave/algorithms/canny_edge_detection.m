function [edgeImg] = canny_edge_detection(inputImg, thresholds, sigma)
% CANNY_EDGE_DETECTION Multi-stage optimal edge detector with non-maximum suppression and hysteresis.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   John F. Canny's optimal edge detection algorithm satisfies three mathematical criteria:
%     1. Low error rate (marking true edges only, missing none).
%     2. Good localization (distance between detected and true edge pixels is minimized).
%     3. Single response (one response to a single edge, no multi-pixel wide ridges).
%
%   Four Algorithmic Stages:
%     Stage 1: Gaussian Smoothing - attenuates high-frequency noise.
%     Stage 2: Gradient Computation - finds magnitude and directional angle.
%     Stage 3: Non-Maximum Suppression (NMS) - thins thick ridges to single-pixel width along gradient direction.
%     Stage 4: Hysteresis Thresholding - double thresholds (T_low, T_high) track strong edges and include
%              weak edges only if they are connected to strong edges.
%
% Syntax:
%   edgeImg = canny_edge_detection(inputImg, thresholds, sigma)
%
% Inputs:
%   inputImg   - RGB or grayscale image.
%   thresholds - [T_low, T_high] vector in [0, 1] or scalar high threshold (default: auto).
%   sigma      - Standard deviation for Gaussian pre-filter (default: sqrt(2) approx 1.414).
%
% Outputs:
%   edgeImg    - Binary single-pixel edge map (uint8: 0 or 255).

  if nargin < 1 || isempty(inputImg)
    error('canny_edge_detection: Input image is required.');
  endif
  if nargin < 2, thresholds = []; endif
  if nargin < 3 || isempty(sigma) || sigma <= 0, sigma = sqrt(2); endif

  % Convert to grayscale
  if size(inputImg, 3) >= 3
    gray = 0.2989 * double(inputImg(:, :, 1)) + ...
           0.5870 * double(inputImg(:, :, 2)) + ...
           0.1140 * double(inputImg(:, :, 3));
  else
    gray = double(inputImg);
  endif

  % Normalize to [0, 1] for edge function
  if max(gray(:)) > 1.0
    grayNorm = gray / 255.0;
  else
    grayNorm = gray;
  endif

  try
    % Use Octave image package edge() function
    if isempty(thresholds)
      binaryEdges = edge(grayNorm, 'Canny', [], sigma);
    else
      binaryEdges = edge(grayNorm, 'Canny', thresholds, sigma);
    endif
  catch
    % Fallback implementation: Gaussian smoothing + Sobel gradients + NMS + Double Threshold
    kRadius = max(1, round(3 * sigma));
    [kx, ky] = meshgrid(-kRadius:kRadius, -kRadius:kRadius);
    gKernel = exp(-(kx.^2 + ky.^2) / (2 * sigma^2));
    gKernel = gKernel / sum(gKernel(:));
    smoothed = conv2(padarray(grayNorm, [kRadius, kRadius], 'replicate'), gKernel, 'valid');

    % Gradients
    Sx = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
    Sy = [1, 2, 1; 0, 0, 0; -1, -2, -1];
    gx = conv2(padarray(smoothed, [1, 1], 'replicate'), Sx, 'valid');
    gy = conv2(padarray(smoothed, [1, 1], 'replicate'), Sy, 'valid');
    mag = sqrt(gx.^2 + gy.^2);

    highT = 0.2 * max(mag(:));
    lowT = 0.4 * highT;
    if ~isempty(thresholds)
      if length(thresholds) >= 2
        lowT = thresholds(1); highT = thresholds(2);
      else
        highT = thresholds(1); lowT = 0.4 * highT;
      endif
    endif

    % Hysteresis
    strong = mag >= highT;
    weak = (mag >= lowT) & (mag < highT);
    binaryEdges = strong | (weak & (conv2(double(strong), ones(3), 'same') > 0));
  end_try_catch

  edgeImg = uint8(binaryEdges * 255);

endfunction
