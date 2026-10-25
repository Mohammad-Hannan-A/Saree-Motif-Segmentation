function [enhancedImg, histBefore, histAfter] = histogram_equalization(inputImg)
% HISTOGRAM_EQUALIZATION Flattens the image histogram to enhance global contrast.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Histogram equalization spreads out the most frequent intensity values across the entire
%   dynamic range [0, L-1]. It utilizes the Cumulative Distribution Function (CDF):
%     s_k = T(r_k) = (L - 1) * sum_{j=0}^k (n_j / N)
%   For color RGB images, equalization is performed in the HSV color space on the Value (V)
%   channel, or in YCbCr on the Luminance (Y) channel. This preserves chromaticity (Hue and
%   Saturation) while preventing unsightly artificial color distortions.
%
% Syntax:
%   [enhancedImg, histBefore, histAfter] = histogram_equalization(inputImg)
%
% Inputs:
%   inputImg    - Grayscale or RGB image.
% Outputs:
%   enhancedImg - Contrast-enhanced image with uniformized intensity histogram.
%   histBefore  - 256-element frequency vector before equalization.
%   histAfter   - 256-element frequency vector after equalization.

  if nargin < 1 || isempty(inputImg)
    error('histogram_equalization: Input image is required.');
  endif

  [rows, cols, channels] = size(inputImg);

  if channels == 1
    % Single-channel Grayscale Equalization
    gray = double(inputImg);
    if max(gray(:)) <= 1.0 && isfloat(inputImg)
      gray = gray * 255.0;
    endif

    histBefore = hist(gray(:), 0:255);
    numPixels = rows * cols;
    cdf = cumsum(histBefore) / numPixels;

    % Transformation lookup table
    lut = round(cdf * 255.0);
    enhancedDouble = lut(round(gray) + 1);

    enhancedImg = cast(enhancedDouble, class(inputImg));
    histAfter = hist(enhancedDouble(:), 0:255);

  elseif channels >= 3
    % For RGB: Convert to HSV, equalize V channel, convert back to RGB
    rgb = inputImg(:, :, 1:3);
    if isinteger(rgb)
      rgbDouble = double(rgb) / 255.0;
    else
      rgbDouble = double(rgb);
      if max(rgbDouble(:)) > 1.0, rgbDouble = rgbDouble / 255.0; endif
    endif

    hsv = rgb2hsv(rgbDouble);
    vChannel = round(hsv(:, :, 3) * 255.0);

    histBefore = hist(vChannel(:), 0:255);
    numPixels = rows * cols;
    cdf = cumsum(histBefore) / numPixels;
    lut = cdf; % Normalized [0, 1]

    eqV = lut(vChannel + 1);
    hsv(:, :, 3) = eqV;

    eqRGB = hsv2rgb(hsv);
    enhancedImg = cast(round(eqRGB * 255.0), 'uint8');
    histAfter = hist(round(eqV(:) * 255.0), 0:255);
  endif

endfunction
