function [filteredImg] = medianFilter(inputImg, windowSize)
% MEDIANFILTER Removes impulse (salt-and-pepper) noise using a 2D median filter.
%
% Syntax:
%   filteredImg = medianFilter(inputImg, windowSize)
%
% Inputs:
%   inputImg   - Grayscale or RGB image matrix.
%   windowSize - (Optional) Scalar or 2-element vector specifying window [M N]. Default is 3 (i.e. [3 3]).
%
% Outputs:
%   filteredImg - Filtered image preserving sharp motif edges while eliminating impulse spikes.
%
% Theory:
%   Unlike linear smoothing filters that blur edges, the median filter replaces each
%   pixel with the median value of its neighborhood. This effectively removes extreme
%   intensity spikes (fabric dust, camera sensor noise) without softening sharp motif boundaries.

  if nargin < 1 || isempty(inputImg)
    error('medianFilter: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(windowSize)
    windowSize = [3, 3];
  elseif isscalar(windowSize)
    windowSize = [windowSize, windowSize];
  endif

  [rows, cols, channels] = size(inputImg);
  filteredImg = zeros(rows, cols, channels, class(inputImg));

  % Check if medfilt2 is available from the Octave image package
  hasMedfilt2 = exist('medfilt2', 'file') || exist('medfilt2', 'builtin');

  for c = 1:channels
    channelData = inputImg(:, :, c);
    if hasMedfilt2
      filteredImg(:, :, c) = medfilt2(channelData, windowSize);
    else
      filteredImg(:, :, c) = medianFilter2D_internal(channelData, windowSize);
    endif
  endfor

endfunction

% Helper 2D median filter fallback if image package is not preloaded
function out = medianFilter2D_internal(channelImg, wSize)
  wR = wSize(1);
  wC = wSize(2);
  padR = floor(wR / 2);
  padC = floor(wC / 2);

  [rows, cols] = size(channelImg);
  % Pad with replication
  padded = padarray_internal(channelImg, [padR, padC]);
  out = zeros(rows, cols, class(channelImg));

  for r = 1:rows
    for c = 1:cols
      patch = padded(r:(r + wR - 1), c:(c + wC - 1));
      out(r, c) = median(patch(:));
    endfor
  endfor
endfunction

function padded = padarray_internal(img, padSizes)
  rPad = padSizes(1);
  cPad = padSizes(2);
  topRows = repmat(img(1, :), rPad, 1);
  botRows = repmat(img(end, :), rPad, 1);
  v = [topRows; img; botRows];
  leftCols = repmat(v(:, 1), 1, cPad);
  rightCols = repmat(v(:, end), 1, cPad);
  padded = [leftCols, v, rightCols];
endfunction
