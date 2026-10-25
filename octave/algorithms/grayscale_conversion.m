function [grayImg] = grayscale_conversion(inputImg)
% GRAYSCALE_CONVERSION Converts an RGB color image into a single-channel grayscale image.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Human visual perception does not perceive all light wavelengths with equal sensitivity.
%   The human eye possesses cone photoreceptors most sensitive to green, moderately to red,
%   and least to blue. The ITU-R BT.601 / NTSC standard luminosity equation weights RGB channels:
%
%   Y = 0.2989 * R + 0.5870 * G + 0.1140 * B
%
% Syntax:
%   grayImg = grayscale_conversion(inputImg)
%
% Inputs:
%   inputImg - RGB image (uint8 or double) [M x N x 3] or grayscale [M x N].
% Outputs:
%   grayImg  - 2D grayscale image matrix [M x N].

  if nargin < 1 || isempty(inputImg)
    error('grayscale_conversion: An input image matrix is required.');
  endif

  [rows, cols, channels] = size(inputImg);

  if channels == 1
    % Already single-channel grayscale
    grayImg = inputImg;
    return;
  elseif channels == 3 || channels == 4
    % Extract R, G, B channels as double precision floats
    r = double(inputImg(:, :, 1));
    g = double(inputImg(:, :, 2));
    b = double(inputImg(:, :, 3));

    % Compute weighted luminance
    luminance = 0.2989 * r + 0.5870 * g + 0.1140 * b;

    % Preserve data type
    if isinteger(inputImg)
      grayImg = cast(round(luminance), class(inputImg));
    else
      grayImg = luminance;
    endif
  else
    error('grayscale_conversion: Image must have 1, 3, or 4 color channels.');
  endif

endfunction
