function [negImg] = image_negative(inputImg)
% IMAGE_NEGATIVE Computes the photographic negative of an image.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   The photographic negative transformation inverts the dynamic range of pixel values:
%     s = L - 1 - r
%   where r is the input intensity and L is the number of intensity levels (256 for 8-bit).
%   In an 8-bit image [0, 255]:
%     Output = 255 - Input
%   For saree fabrics, negative inversion helps highlight intricate zari/metallic borders
%   against dark fabrics by making fine dark outlines brightly visible.
%
% Syntax:
%   negImg = image_negative(inputImg)
%
% Inputs:
%   inputImg - RGB [M x N x 3] or grayscale [M x N] image.
% Outputs:
%   negImg   - Inverted image of identical dimensions and data type.

  if nargin < 1 || isempty(inputImg)
    error('image_negative: Input image is required.');
  endif

  if islogical(inputImg)
    negImg = ~inputImg;
  elseif isinteger(inputImg)
    maxVal = intmax(class(inputImg));
    negImg = maxVal - inputImg;
  else
    % Double or single normalized to [0, 1]
    if max(inputImg(:)) <= 1.0
      negImg = 1.0 - inputImg;
    else
      negImg = 255.0 - inputImg;
    endif
  endif

endfunction
