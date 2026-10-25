function [filteredImg] = median_filtering(inputImg, windowSize)
% MEDIAN_FILTERING Removes impulse (salt-and-pepper) noise while preserving sharp motif edges.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Linear smoothing filters (like average and Gaussian) blur sharp motif boundaries.
%   In contrast, the 2D Median Filter replaces each pixel value with the median of neighboring
%   pixels in an M x M spatial window:
%     g(x, y) = median { f(s, t) : (s, t) in S_{x,y} }
%   Because the median is an order statistic and does not average values, isolated noise spikes
%   (white or black specks from camera sensors or fabric dust) are completely discarded without
%   degrading the sharp contrast of zari embroidery edges.
%
% Syntax:
%   filteredImg = median_filtering(inputImg, windowSize)
%
% Inputs:
%   inputImg   - RGB or grayscale image.
%   windowSize - Odd integer (3, 5, 7). Default: 3.
%
% Outputs:
%   filteredImg - Noise-reduced image with crisp boundaries.

  if nargin < 1 || isempty(inputImg)
    error('median_filtering: Input image is required.');
  endif
  if nargin < 2 || isempty(windowSize) || windowSize < 1
    windowSize = 3;
  endif

  windowSize = round(windowSize);
  if mod(windowSize, 2) == 0
    windowSize = windowSize + 1;
  endif

  [rows, cols, channels] = size(inputImg);
  filteredImg = zeros(rows, cols, channels, class(inputImg));

  for c = 1:channels
    plane = inputImg(:, :, c);
    try
      filteredPlane = medfilt2(plane, [windowSize, windowSize]);
    catch
      % Pure algorithmic median filter fallback
      radius = floor(windowSize / 2);
      padded = padarray(double(plane), [radius, radius], 'replicate');
      filteredPlane = zeros(rows, cols);

      for i = 1:rows
        for j = 1:cols
          window = padded(i:(i + 2 * radius), j:(j + 2 * radius));
          filteredPlane(i, j) = median(window(:));
        endfor
      endfor
      filteredPlane = cast(round(filteredPlane), class(plane));
    end_try_catch

    filteredImg(:, :, c) = filteredPlane;
  endfor

endfunction
