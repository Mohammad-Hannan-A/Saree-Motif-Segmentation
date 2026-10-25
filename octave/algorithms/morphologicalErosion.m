function [erodedImg] = morphologicalErosion(inputImg, seShape, seSize)
% MORPHOLOGICALEROSION Shrinks foreground regions and eliminates fine background noise spikes.
%
% Syntax:
%   erodedImg = morphologicalErosion(inputImg, seShape, seSize)
%
% Inputs:
%   inputImg - Binary or grayscale image matrix.
%   seShape  - (Optional) Structuring element shape: 'disk', 'square', or 'diamond'. Default is 'disk'.
%   seSize   - (Optional) Radius or half-width of the structuring element. Default is 2.
%
% Outputs:
%   erodedImg - Morphologically eroded image of the same class.
%
% Theory:
%   Mathematical erosion computes the minimum value under the structuring element:
%     (A (-) B)(x, y) = min_{(i, j) in B} A(x + i, y + j)
%   For binary masks, erosion peels away the outer boundary of motifs and severs thin
%   parasitic connections to neighboring patterns.

  if nargin < 1 || isempty(inputImg)
    error('morphologicalErosion: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(seShape)
    seShape = 'disk';
  endif

  if nargin < 3 || isempty(seSize)
    seSize = 2;
  endif

  % Ensure Octave image package is loaded
  if ~exist('imerode', 'file') && ~exist('imerode', 'builtin')
    pkg load image;
  endif

  se = create_strel(seShape, seSize);
  erodedImg = imerode(inputImg, se);

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
