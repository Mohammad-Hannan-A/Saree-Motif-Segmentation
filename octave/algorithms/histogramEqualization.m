function [equalizedImg, histBefore, histAfter] = histogramEqualization(inputImg)
% HISTOGRAMEQUALIZATION Improves image contrast using cumulative distribution function (CDF) flattening.
%
% Syntax:
%   [equalizedImg, histBefore, histAfter] = histogramEqualization(inputImg)
%
% Inputs:
%   inputImg    - Grayscale or RGB image.
%
% Outputs:
%   equalizedImg - Contrast-equalized image.
%   histBefore   - 256-element vector of intensity counts before equalization.
%   histAfter    - 256-element vector of intensity counts after equalization.
%
% Theory:
%   Histogram equalization calculates the normalized cumulative distribution function (CDF)
%   of pixel intensities and uses it as a monotonic transfer function:
%     s_k = round((L - 1) * sum_{j=0}^k (n_j / N))
%   This redistributes clustered intensity levels evenly across [0, 255].
%   For RGB images, equalization is performed on the luminance/Value channel
%   to enhance motif details while preventing color artifact distortion.

  if nargin < 1 || isempty(inputImg)
    error('histogramEqualization: InvalidInput, input image is required.');
  endif

  [rows, cols, channels] = size(inputImg);

  if channels == 1
    % Single channel grayscale
    grayImg = uint8(inputImg);
    histBefore = compute_hist(grayImg);
    equalizedImg = equalize_channel(grayImg);
    histAfter = compute_hist(equalizedImg);
  else
    % RGB image: Convert to YCbCr or HSV Value to preserve chrominance
    % Compute luminance channel:
    r = double(inputImg(:, :, 1));
    g = double(inputImg(:, :, 2));
    b = double(inputImg(:, :, 3));
    luminance = uint8(round(0.2989 * r + 0.5870 * g + 0.1140 * b));

    histBefore = compute_hist(luminance);
    eqLuminance = equalize_channel(luminance);
    histAfter = compute_hist(eqLuminance);

    % Scale RGB channels proportionately by ratio: eqLuminance / (luminance + eps)
    ratio = double(eqLuminance) ./ (double(luminance) + 1.0);
    equalizedImg = zeros(rows, cols, 3, 'uint8');

    for c = 1:3
      ch = double(inputImg(:, :, c)) .* ratio;
      equalizedImg(:, :, c) = uint8(max(0, min(255, round(ch))));
    endfor
  endif

endfunction

function eqChannel = equalize_channel(imgChannel)
  % Compute normalized histogram and CDF
  counts = compute_hist(imgChannel);
  numPixels = numel(imgChannel);
  cdf = cumsum(counts) / numPixels;

  % Lookup table mapping [0..255]
  lookupTable = uint8(round(cdf * 255));

  % Apply mapping (1-based index in Octave: pixel value 0 -> index 1)
  eqChannel = lookupTable(double(imgChannel) + 1);
endfunction

function counts = compute_hist(imgChannel)
  counts = hist(double(imgChannel(:)), 0:255);
  counts = counts(:); % Column vector
endfunction
