function [binMask, distMap] = colorSegmentation(inputImg, targetColor, tolerance, colorSpace)
% COLORSEGMENTATION Segments motifs based on color similarity in RGB or HSV color space.
%
% Syntax:
%   [binMask, distMap] = colorSegmentation(inputImg, targetColor, tolerance, colorSpace)
%
% Inputs:
%   inputImg    - RGB image matrix [M x N x 3].
%   targetColor - 3-element vector [C1, C2, C3]:
%                 - For RGB: [R, G, B] values in [0, 255] (e.g., [212, 175, 55] for gold zari).
%                 - For HSV: [H, S, V] with H in [0, 360], S in [0, 1], V in [0, 1].
%   tolerance   - (Optional) Positive distance threshold. Default is 45 for RGB or 0.25 for HSV.
%   colorSpace  - (Optional) String 'RGB' or 'HSV'. Default is 'RGB'.
%
% Outputs:
%   binMask     - Binary segmentation mask (uint8, 0 or 255).
%   distMap     - Normalized color distance map.
%
% Theory:
%   Traditional Indian sarees frequently feature metallic zari (gold/silver) or contrast
%   dyed silk threads (peacock blue, mango yellow, parrot green) against dark fabrics.
%   Color segmentation measures the Euclidean distance of each pixel's color vector
%   from the target motif color:
%     d(x, y) = || C(x, y) - C_target ||
%   Pixels with d(x, y) <= tolerance are marked as foreground.

  if nargin < 1 || isempty(inputImg)
    error('colorSegmentation: InvalidInput, input image is required.');
  endif

  if size(inputImg, 3) < 3
    error('colorSegmentation: DimensionError, color segmentation requires a 3-channel RGB image.');
  endif

  if nargin < 2 || isempty(targetColor)
    % Default target: golden zari [218, 165, 32]
    targetColor = [218, 165, 32];
  endif

  if nargin < 4 || isempty(colorSpace)
    colorSpace = 'RGB';
  endif

  if nargin < 3 || isempty(tolerance)
    if strcmpi(colorSpace, 'HSV')
      tolerance = 0.25;
    else
      tolerance = 50.0;
    endif
  endif

  imgDouble = double(inputImg);

  if strcmpi(colorSpace, 'HSV')
    % Convert to HSV
    if ~exist('rgb2hsv', 'file') && ~exist('rgb2hsv', 'builtin')
      pkg load image;
    endif
    hsvImg = rgb2hsv(imgDouble / 255.0);

    % Target HSV normalized
    tH = targetColor(1) / 360.0;
    tS = targetColor(2);
    tV = targetColor(3);

    % Circular distance for Hue (angle on color wheel)
    deltaH = abs(hsvImg(:, :, 1) - tH);
    deltaH = min(deltaH, 1.0 - deltaH);
    deltaS = abs(hsvImg(:, :, 2) - tS);
    deltaV = abs(hsvImg(:, :, 3) - tV);

    % Weighted HSV distance (Hue weighted more for chromatic discrimination)
    distMap = sqrt((2.0 * deltaH).^2 + deltaS.^2 + deltaV.^2);
    logicalMask = (distMap <= tolerance);
  else
    % Standard Euclidean distance in RGB space
    tR = targetColor(1);
    tG = targetColor(2);
    tB = targetColor(3);

    dR = imgDouble(:, :, 1) - tR;
    dG = imgDouble(:, :, 2) - tG;
    dB = imgDouble(:, :, 3) - tB;

    distMap = sqrt(dR.^2 + dG.^2 + dB.^2);
    logicalMask = (distMap <= tolerance);
  endif

  binMask = uint8(logicalMask * 255);

endfunction
