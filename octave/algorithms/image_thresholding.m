function [threshImg, calculatedThresh] = image_thresholding(inputImg, thresholdVal, invert)
% IMAGE_THRESHOLDING Converts an image into a binary black-and-white mask via intensity thresholding.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Intensity thresholding partitions pixel intensities into foreground and background classes:
%     g(x, y) = 1 if f(x, y) >= T, else 0
%   When thresholdVal is -1 or empty, Otsu's optimal global thresholding algorithm is used:
%   It maximizes inter-class variance sigma_B^2(T) = w0(T)*w1(T)*[mu0(T) - mu1(T)]^2.
%
% Syntax:
%   [threshImg, calculatedThresh] = image_thresholding(inputImg, thresholdVal, invert)
%
% Inputs:
%   inputImg     - Grayscale or RGB image.
%   thresholdVal - Value in [0, 255] or -1 for automatic Otsu's thresholding.
%   invert       - Boolean (default: false). If true, inverts binary mask.
%
% Outputs:
%   threshImg        - Binary mask (uint8: 0 and 255).
%   calculatedThresh - The numeric threshold used [0, 255].

  if nargin < 1 || isempty(inputImg)
    error('image_thresholding: Input image is required.');
  endif
  if nargin < 2 || isempty(thresholdVal)
    thresholdVal = -1; % Default: Auto Otsu
  endif
  if nargin < 3 || isempty(invert)
    invert = false;
  endif

  % Convert to grayscale if RGB
  if size(inputImg, 3) >= 3
    gray = 0.2989 * double(inputImg(:, :, 1)) + ...
           0.5870 * double(inputImg(:, :, 2)) + ...
           0.1140 * double(inputImg(:, :, 3));
  else
    gray = double(inputImg);
  endif

  % Ensure values are scaled to [0, 255]
  if max(gray(:)) <= 1.0 && min(gray(:)) >= 0.0
    gray = gray * 255.0;
  endif

  if thresholdVal < 0
    % Otsu's Method for Automatic Global Thresholding
    counts = hist(gray(:), 0:255);
    total = sum(counts);
    sumAll = sum((0:255) .* counts);
    sumB = 0;
    wB = 0;
    maxVariance = 0;
    bestT = 128;

    for t = 0:255
      wB = wB + counts(t + 1);
      if wB == 0, continue; endif
      wF = total - wB;
      if wF == 0, break; endif

      sumB = sumB + t * counts(t + 1);
      mB = sumB / wB;
      mF = (sumAll - sumB) / wF;

      varBetween = double(wB) * double(wF) * ((mB - mF)^2);
      if varBetween > maxVariance
        maxVariance = varBetween;
        bestT = t;
      endif
    endfor
    calculatedThresh = bestT;
  else
    calculatedThresh = min(255, max(0, round(thresholdVal)));
  endif

  % Apply threshold
  if invert
    mask = gray < calculatedThresh;
  else
    mask = gray >= calculatedThresh;
  endif

  threshImg = uint8(mask * 255);

endfunction
