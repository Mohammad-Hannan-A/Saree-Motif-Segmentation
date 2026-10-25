function [segmentedImg, colorMask] = color_based_segmentation(inputImg, targetColor, tolerance, colorSpace)
% COLOR_BASED_SEGMENTATION Isolates saree motifs based on chromatic Euclidean distance to a target color.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Saree embroidery and border motifs often have distinct color signatures
%   (e.g., golden zari metallic thread, vibrant crimson floral silk, silver border).
%   Color-based segmentation computes the Euclidean distance in RGB or HSV color space:
%     d(x, y) = || C(x, y) - C_{target} ||
%   Pixels with d(x, y) <= tolerance are classified as motif foreground.
%
% Syntax:
%   [segmentedImg, colorMask] = color_based_segmentation(inputImg, targetColor, tolerance, colorSpace)
%
% Inputs:
%   inputImg    - RGB image [M x N x 3].
%   targetColor - [R, G, B] vector (default: [218, 165, 32] - Traditional Gold Zari).
%   tolerance   - Distance threshold (default: 55, range: 10 to 150).
%   colorSpace  - 'RGB' or 'HSV' (default: 'RGB').
%
% Outputs:
%   segmentedImg - Image with non-matching background dimmed to 20% opacity.
%   colorMask    - Logical binary mask of the detected motif region.

  if nargin < 1 || isempty(inputImg)
    error('color_based_segmentation: Input image is required.');
  endif
  if nargin < 2 || isempty(targetColor)
    targetColor = [218, 165, 32]; % Default Golden Zari
  endif
  if nargin < 3 || isempty(tolerance) || tolerance <= 0
    tolerance = 55;
  endif
  if nargin < 4 || isempty(colorSpace)
    colorSpace = 'RGB';
  endif

  [rows, cols, channels] = size(inputImg);
  if channels == 1
    rgb = repmat(inputImg, [1, 1, 3]);
  else
    rgb = inputImg(:, :, 1:3);
  endif

  R = double(rgb(:, :, 1));
  G = double(rgb(:, :, 2));
  B = double(rgb(:, :, 3));

  targetColor = double(targetColor(:)');

  if strcmpi(colorSpace, 'HSV')
    % Convert image to HSV
    hsv = rgb2hsv(double(rgb) / 255.0);
    targetHSV = rgb2hsv(reshape(targetColor / 255.0, [1, 1, 3]));
    tH = targetHSV(1); tS = targetHSV(2); tV = targetHSV(3);

    % Circular distance on Hue channel
    dH = min(abs(hsv(:, :, 1) - tH), 1 - abs(hsv(:, :, 1) - tH));
    dS = abs(hsv(:, :, 2) - tS);
    dV = abs(hsv(:, :, 3) - tV);

    % Weighted HSV distance (Hue weighted 2x)
    dist = sqrt((2 * dH).^2 + dS.^2 + (0.5 * dV).^2) * 255.0;
  else
    % Standard RGB Euclidean metric
    dist = sqrt((R - targetColor(1)).^2 + ...
                (G - targetColor(2)).^2 + ...
                (B - targetColor(3)).^2);
  endif

  colorMask = dist <= tolerance;

  % Produce visualization: Preserve foreground colors; dim background to dark muted tones
  segmentedImg = uint8(rgb);
  for c = 1:3
    ch = double(rgb(:, :, c));
    ch(~colorMask) = ch(~colorMask) * 0.25; % Dim background
    segmentedImg(:, :, c) = uint8(ch);
  endfor

endfunction
