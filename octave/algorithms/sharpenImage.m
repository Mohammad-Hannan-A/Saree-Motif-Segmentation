function [sharpenedImg] = sharpenImage(inputImg, strength)
% SHARPENIMAGE Enhances fine structural details, zari borders, and motif contours.
%
% Syntax:
%   sharpenedImg = sharpenImage(inputImg, strength)
%
% Inputs:
%   inputImg - Grayscale or RGB image.
%   strength - (Optional) Positive multiplier for the high-frequency boost. Default is 1.0.
%
% Outputs:
%   sharpenedImg - Detail-enhanced image of the same class and size.
%
% Theory:
%   Sharpening is implemented using Unsharp Masking / Laplacian high-pass filtering:
%     I_sharp = I_original + strength * (I_original - I_blurred)
%   High-frequency differences (edges, embroidery stitches, fine gold threads) are amplified,
%   making decorative motifs stand out distinctly from woven backgrounds.

  if nargin < 1 || isempty(inputImg)
    error('sharpenImage: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(strength)
    strength = 1.0;
  endif

  imgDouble = double(inputImg);
  [rows, cols, channels] = size(inputImg);

  % Laplacian edge-enhancement kernel
  % Center value 4 + 4*strength or unsharp mask via Gaussian difference
  sigma = 1.0;
  halfSize = 2;
  [X, Y] = meshgrid(-halfSize:halfSize, -halfSize:halfSize);
  gauss = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
  gauss = gauss / sum(gauss(:));

  sharpenedDouble = zeros(rows, cols, channels);

  for c = 1:channels
    blurred = conv2(imgDouble(:, :, c), gauss, 'same');
    detail = imgDouble(:, :, c) - blurred;
    sharpenedDouble(:, :, c) = imgDouble(:, :, c) + strength * detail;
  endfor

  % Clip values to valid range and cast back
  if isa(inputImg, 'uint8')
    sharpenedImg = uint8(max(0, min(255, round(sharpenedDouble))));
  elseif isa(inputImg, 'uint16')
    sharpenedImg = uint16(max(0, min(65535, round(sharpenedDouble))));
  else
    sharpenedImg = sharpenedDouble;
  endif

endfunction
