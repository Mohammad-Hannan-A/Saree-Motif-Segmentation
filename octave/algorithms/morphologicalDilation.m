function [dilatedImg] = morphologicalDilation(inputImg, seShape, seSize)
% MORPHOLOGICALDILATION Expands foreground regions and closes small interior gaps.
%
% Syntax:
%   dilatedImg = morphologicalDilation(inputImg, seShape, seSize)
%
% Inputs:
%   inputImg - Binary or grayscale image matrix.
%   seShape  - (Optional) Structuring element shape: 'disk', 'square', or 'diamond'. Default is 'disk'.
%   seSize   - (Optional) Radius or half-width of the structuring element. Default is 2.
%
% Outputs:
%   dilatedImg - Morphologically dilated image of the same class.
%
% Theory:
%   Mathematical dilation computes the maximum value under the structuring element:
%     (A (+) B)(x, y) = max_{(i, j) in B} A(x - i, y - j)
%   For motif segmentation, dilation repairs broken zari thread lines and connects fragmented
%   petals or leaves into cohesive motif segments.

  if nargin < 1 || isempty(inputImg)
    error('morphologicalDilation: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(seShape)
    seShape = 'disk';
  endif

  if nargin < 3 || isempty(seSize)
    seSize = 2;
  endif

  % Ensure Octave image package is loaded
  if ~exist('imdilate', 'file') && ~exist('imdilate', 'builtin')
    pkg load image;
  endif

  se = create_strel(seShape, seSize);
  dilatedImg = imdilate(inputImg, se);

endfunction

function se = create_strel(shape, sz)
  sz = max(1, round(sz));
  switch lower(shape)
    case 'disk'
      se = strel('disk', sz, 0);
    case 'square'
      se = strel('square', 2 * sz + 1);
    case 'diamond'
      se = strel('diamond', sz);
    otherwise
      se = strel('disk', sz, 0);
  endswitch
endfunction
