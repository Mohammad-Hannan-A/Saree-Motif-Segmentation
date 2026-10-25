function [enhancedImg] = contrastEnhancement(inputImg, lowClip, highClip)
% CONTRASTENHANCEMENT Performs linear contrast stretching with percentile clipping.
%
% Syntax:
%   enhancedImg = contrastEnhancement(inputImg, lowClip, highClip)
%
% Inputs:
%   inputImg - Grayscale or RGB image.
%   lowClip  - (Optional) Lower intensity percentile cut-off (0 to 0.1). Default is 0.01 (1%).
%   highClip - (Optional) Upper intensity percentile cut-off (0.9 to 1.0). Default is 0.99 (99%).
%
% Outputs:
%   enhancedImg - Contrast-stretched image with dynamic range expanded to [0, 255].
%
% Theory:
%   Contrast stretching maps the original narrow dynamic range [r_min, r_max] onto the full range [0, 255]:
%     s = ((r - r_min) / (r_max - r_min)) * 255
%   By clipping the lowest 1% and highest 1% outliers, extreme specular highlights or shadows
%   do not prevent effective contrast expansion across the motif embroidery.

  if nargin < 1 || isempty(inputImg)
    error('contrastEnhancement: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(lowClip)
    lowClip = 0.01;
  endif

  if nargin < 3 || isempty(highClip)
    highClip = 0.99;
  endif

  [rows, cols, channels] = size(inputImg);
  imgDouble = double(inputImg);
  enhancedDouble = zeros(rows, cols, channels);

  for c = 1:channels
    channelData = imgDouble(:, :, c);
    sortedVals = sort(channelData(:));
    N = length(sortedVals);

    minIdx = max(1, round(lowClip * N));
    maxIdx = min(N, round(highClip * N));

    rMin = sortedVals(minIdx);
    rMax = sortedVals(maxIdx);

    if rMax > rMin
      stretched = (channelData - rMin) / (rMax - rMin) * 255.0;
    else
      stretched = channelData;
    endif

    enhancedDouble(:, :, c) = max(0, min(255, stretched));
  endfor

  if isa(inputImg, 'uint8')
    enhancedImg = uint8(round(enhancedDouble));
  elseif isa(inputImg, 'uint16')
    enhancedImg = uint16(round(enhancedDouble / 255.0 * 65535));
  else
    enhancedImg = enhancedDouble / 255.0;
  endif

endfunction
