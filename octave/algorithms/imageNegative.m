function [negImg] = imageNegative(inputImg)
% IMAGENEGATIVE Computes the negative (inverted colors) of an image.
%
% Syntax:
%   negImg = imageNegative(inputImg)
%
% Inputs:
%   inputImg - Grayscale or RGB image matrix (uint8, uint16, double, or logical).
%
% Outputs:
%   negImg   - Image with inverted intensities, preserving original size and class.
%
% Algorithm:
%   For an 8-bit image with intensity range [0, 255]:
%     s = L - 1 - r = 255 - r
%   For a normalized floating-point image in [0.0, 1.0]:
%     s = 1.0 - r
%   For a binary/logical image:
%     s = ~r
%
% Purpose:
%   Negative transformation reverses the contrast of an image. Dark motifs on
%   a light saree background become bright, facilitating thresholding and
%   boundary extraction.

  if nargin < 1 || isempty(inputImg)
    error('imageNegative: InvalidInput, input image must not be empty.');
  endif

  if islogical(inputImg)
    negImg = ~inputImg;
  elseif isa(inputImg, 'uint8')
    negImg = 255 - inputImg;
  elseif isa(inputImg, 'uint16')
    negImg = 65535 - inputImg;
  elseif isfloat(inputImg)
    maxVal = max(inputImg(:));
    if maxVal <= 1.0
      negImg = 1.0 - inputImg;
    else
      negImg = 255.0 - inputImg;
    endif
  else
    error('imageNegative: UnsupportedType, input must be uint8, uint16, float, or logical.');
  endif

endfunction
