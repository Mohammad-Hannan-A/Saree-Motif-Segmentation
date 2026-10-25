function [grayImg] = grayscale(inputImg)
% GRAYSCALE Converts an RGB color image into a single-channel grayscale image.
%
% Syntax:
%   grayImg = grayscale(inputImg)
%
% Inputs:
%   inputImg - RGB image (uint8 or double) of size [M x N x 3],
%              or an existing grayscale image of size [M x N].
%
% Outputs:
%   grayImg  - Grayscale image of size [M x N] matching the input data type.
%
% Algorithm:
%   Standard ITU-R BT.601 / NTSC luminance formula:
%   Y = 0.2989 * R + 0.5870 * G + 0.1140 * B
%   This matches the human visual perception, which is most sensitive to green
%   and least sensitive to blue.

  % Input validation
  if nargin < 1
    error('grayscale: InvalidInput, an input image matrix is required.');
  endif

  if isempty(inputImg)
    error('grayscale: EmptyImage, input image is empty.');
  endif

  % Check number of channels
  [rows, cols, channels] = size(inputImg);

  if channels == 1
    % Image is already grayscale, return as is
    grayImg = inputImg;
    return;
  elseif channels == 3 || channels == 4
    % Drop alpha if present for grayscale conversion
    r = double(inputImg(:, :, 1));
    g = double(inputImg(:, :, 2));
    b = double(inputImg(:, :, 3));

    % Apply luminance conversion formula
    luminance = 0.2989 * r + 0.5870 * g + 0.1140 * b;

    % Preserve original class type (uint8, uint16, double)
    if isinteger(inputImg)
      grayImg = cast(round(luminance), class(inputImg));
    else
      grayImg = luminance;
    endif
  else
    error('grayscale: UnsupportedDimensions, image must have 1, 3, or 4 channels.');
  endif

endfunction
