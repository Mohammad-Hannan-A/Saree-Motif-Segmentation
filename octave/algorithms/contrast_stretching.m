function [stretchedImg] = contrast_stretching(inputImg, lowPercentile, highPercentile)
% CONTRAST_STRETCHING Linearly scales the dynamic range between minimum and maximum bounds.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Low-contrast images often occupy only a narrow portion of the available [0, 255] intensity range.
%   Contrast stretching (normalization) applies a linear transformation:
%     s = ((r - r_min) / (r_max - r_min)) * (s_max - s_min) + s_min
%   To prevent isolated noise outliers from skewing the stretch, percentiles (e.g., 1% and 99%)
%   are used to robustly define the effective lower (a) and upper (b) clipping bounds.
%
% Syntax:
%   stretchedImg = contrast_stretching(inputImg, lowPercentile, highPercentile)
%
% Inputs:
%   inputImg       - RGB or grayscale image.
%   lowPercentile  - Lower clipping percentile in [0.0, 0.49] (default: 0.01 = 1%).
%   highPercentile - Upper clipping percentile in [0.51, 1.0] (default: 0.99 = 99%).
%
% Outputs:
%   stretchedImg   - Image stretched across the full [0, 255] dynamic range.

  if nargin < 1 || isempty(inputImg)
    error('contrast_stretching: Input image is required.');
  endif
  if nargin < 2 || isempty(lowPercentile), lowPercentile = 0.01; endif
  if nargin < 3 || isempty(highPercentile), highPercentile = 0.99; endif

  [rows, cols, channels] = size(inputImg);
  stretchedImg = zeros(rows, cols, channels, class(inputImg));

  for c = 1:channels
    plane = double(inputImg(:, :, c));
    sortedVals = sort(plane(:));
    N = length(sortedVals);

    lowIdx = max(1, round(lowPercentile * N));
    highIdx = min(N, round(highPercentile * N));

    valMin = sortedVals(lowIdx);
    valMax = sortedVals(highIdx);

    if (valMax - valMin) < 1e-4
      valMax = valMin + 1.0;
    endif

    % Linear stretch formula
    stretched = (plane - valMin) ./ (valMax - valMin) * 255.0;
    stretched(stretched < 0) = 0;
    stretched(stretched > 255) = 255;

    if isinteger(inputImg)
      stretchedImg(:, :, c) = cast(round(stretched), class(inputImg));
    else
      stretchedImg(:, :, c) = stretched / 255.0;
    endif
  endfor

endfunction
