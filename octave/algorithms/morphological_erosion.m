function [outImg] = morphological_erosion(inputImg, seShape, seSize)
% MORPHOLOGICAL_EROSION Shrinks bright foreground structures and eliminates isolated noise artifacts.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Mathematical morphological erosion of image A by structuring element B is defined as:
%     A \ominus B = { z : (B)_z \subseteq A }
%   For grayscale images, it acts as a localized local minimum filter:
%     (f \ominus b)(x, y) = \min_{(s, t) \in B} { f(x + s, y + t) }
%   Effect on Saree Motifs:
%     - Strips away thin extraneous thread protrusions, weaving artifacts, and false background specks.
%     - Separates motifs that are falsely joined by single-pixel thread bridges.
%
% Syntax:
%   outImg = morphological_erosion(inputImg, seShape, seSize)
%
% Inputs:
%   inputImg - Binary (0/255) or Grayscale/RGB image.
%   seShape  - Structuring element shape: 'disk', 'square', 'diamond' (default: 'disk').
%   seSize   - Structuring element radius or half-width (default: 2).
%
% Outputs:
%   outImg   - Morphologically eroded image.

  if nargin < 1 || isempty(inputImg)
    error('morphological_erosion: Input image is required.');
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
      outImg(:, :, c) = imerode(plane, se);
    catch
      % Fallback 2D min order filter
      radius = seSize;
      padded = padarray(double(plane), [radius, radius], 'replicate');
      res = zeros(rows, cols);
      for i = 1:rows
        for j = 1:cols
          window = padded(i:(i + 2 * radius), j:(j + 2 * radius));
          res(i, j) = min(window(:));
        endfor
      endfor
      outImg(:, :, c) = cast(round(res), class(plane));
    end_try_catch
  endfor

endfunction
