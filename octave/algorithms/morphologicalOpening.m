function [openedImg] = morphologicalOpening(inputImg, seShape, seSize)
% MORPHOLOGICALOPENING Eliminates small background specks and smooths object contours.
%
% Syntax:
%   openedImg = morphologicalOpening(inputImg, seShape, seSize)
%
% Inputs:
%   inputImg - Binary or grayscale image matrix.
%   seShape  - (Optional) Structuring element shape: 'disk', 'square', or 'diamond'. Default is 'disk'.
%   seSize   - (Optional) Radius or half-width of the structuring element. Default is 2.
%
% Outputs:
%   openedImg - Resulting image after erosion followed by dilation.
%
% Theory:
%   Morphological opening is defined as erosion followed by dilation by the same structuring element B:
%     A o B = (A (-) B) (+) B
%   It removes foreground noise smaller than the structuring element while preserving
%   the shape and size of primary saree motifs.

  if nargin < 1 || isempty(inputImg)
    error('morphologicalOpening: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(seShape)
    seShape = 'disk';
  endif

  if nargin < 3 || isempty(seSize)
    seSize = 2;
  endif

  % Ensure Octave image package is loaded
  if ~exist('imopen', 'file') && ~exist('imopen', 'builtin')
    pkg load image;
  endif

  sz = max(1, round(seSize));
  switch lower(seShape)
    case 'disk'
      se = strel('disk', sz, 0);
    case 'square'
      se = strel('square', 2 * sz + 1);
    case 'diamond'
      se = strel('diamond', sz);
    otherwise
      se = strel('disk', sz, 0);
  endswitch

  openedImg = imopen(inputImg, se);

endfunction
