function [outImg] = morphological_dilation(inputImg, seShape, seSize)
% MORPHOLOGICAL_DILATION Expands bright object boundaries using a geometric Structuring Element (SE).
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Mathematical morphological dilation of image A by structuring element B is defined as:
%     A \oplus B = { z : (\hat{B})_z \cap A \neq \emptyset }
%   For grayscale images, it acts as a localized local maximum filter:
%     (f \oplus b)(x, y) = \max_{(s, t) \in B} { f(x - s, y - t) }
%   Effect on Saree Motifs:
%     - Bridges tiny disconnected gaps or breaks in fine zari motif boundary lines.
%     - Expands thin embroidery contours to strengthen feature boundaries.
%
% Syntax:
%   outImg = morphological_dilation(inputImg, seShape, seSize)
%
% Inputs:
%   inputImg - Binary (0/255) or Grayscale/RGB image.
%   seShape  - Structuring element shape: 'disk', 'square', 'diamond' (default: 'disk').
%   seSize   - Structuring element radius or half-width (default: 2).
%
% Outputs:
%   outImg   - Morphologically dilated image.

  if nargin < 1 || isempty(inputImg)
    error('morphological_dilation: Input image is required.');
  endif
  if nargin < 2 || isempty(seShape), seShape = 'disk'; endif
  if nargin < 3 || isempty(seSize) || seSize < 1, seSize = 2; endif

  seSize = round(seSize);

  % Create Structuring Element
  try
    switch lower(seShape)
      case 'disk'
        se = strel('disk', seSize);
      case 'square'
        se = strel('square', 2 * seSize + 1);
      case 'diamond'
        se = strel('diamond', seSize);
      otherwise
        se = strel('disk', seSize);
    endswitch
  catch
    se = ones(2 * seSize + 1, 2 * seSize + 1);
  end_try_catch

  [rows, cols, channels] = size(inputImg);
  outImg = zeros(rows, cols, channels, class(inputImg));

  for c = 1:channels
    plane = inputImg(:, :, c);
    try
      outImg(:, :, c) = imdilate(plane, se);
    catch
      % Fallback 2D max order filter
      radius = seSize;
      padded = padarray(double(plane), [radius, radius], 'replicate');
      res = zeros(rows, cols);
      for i = 1:rows
        for j = 1:cols
          window = padded(i:(i + 2 * radius), j:(j + 2 * radius));
          res(i, j) = max(window(:));
        endfor
      endfor
      outImg(:, :, c) = cast(round(res), class(plane));
    end_try_catch
  endfor

endfunction
