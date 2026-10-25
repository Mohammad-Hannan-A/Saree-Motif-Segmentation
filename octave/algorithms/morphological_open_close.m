function [outImg] = morphological_open_close(inputImg, operation, seShape, seSize)
% MORPHOLOGICAL_OPEN_CLOSE Performs morphological opening, closing, or combined filter sequence.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   1. Morphological Opening (Erosion followed by Dilation):
%        A \circ B = (A \ominus B) \oplus B
%      Effect: Eliminates small bright noise specks, detaches thin thread bridges,
%      and smooths sharp object contours from the outside without substantially changing area.
%
%   2. Morphological Closing (Dilation followed by Erosion):
%        A \bullet B = (A \oplus B) \ominus B
%      Effect: Fills small dark voids, pores, and thread gaps within the motif body,
%      bridges narrow boundary fractures, and smooths contours from the inside.
%
%   3. Combined ('both' - Opening then Closing):
%      Cleans background specks first (opening), then completely seals internal fabric holes (closing).
%
% Syntax:
%   outImg = morphological_open_close(inputImg, operation, seShape, seSize)
%
% Inputs:
%   inputImg  - Binary (0/255) or Grayscale/RGB image.
%   operation - 'opening', 'closing', or 'both' (default: 'both').
%   seShape   - Structuring element shape: 'disk', 'square', 'diamond' (default: 'disk').
%   seSize    - Structuring element radius (default: 2).
%
% Outputs:
%   outImg    - Morphologically filtered image.

  if nargin < 1 || isempty(inputImg)
    error('morphological_open_close: Input image is required.');
  endif
  if nargin < 2 || isempty(operation), operation = 'both'; endif
  if nargin < 3 || isempty(seShape), seShape = 'disk'; endif
  if nargin < 4 || isempty(seSize) || seSize < 1, seSize = 2; endif

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

    switch lower(operation)
      case 'opening'
        % Erosion then Dilation
        try
          res = imopen(plane, se);
        catch
          res = imdilate(imerode(plane, se), se);
        end_try_catch

      case 'closing'
        % Dilation then Erosion
        try
          res = imclose(plane, se);
        catch
          res = imerode(imdilate(plane, se), se);
        end_try_catch

      case {'both', 'open_close'}
        % Sequence: Opening (removes noise) followed by Closing (fills internal holes)
        try
          opened = imopen(plane, se);
          res = imclose(opened, se);
        catch
          opened = imdilate(imerode(plane, se), se);
          res = imerode(imdilate(opened, se), se);
        end_try_catch

      otherwise
        error(sprintf('morphological_open_close: Unknown operation "%s". Use "opening", "closing", or "both".', operation));
    endswitch

    outImg(:, :, c) = res;
  endfor

endfunction
