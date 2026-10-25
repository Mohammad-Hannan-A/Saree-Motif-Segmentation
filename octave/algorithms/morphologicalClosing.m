function [closedImg] = morphologicalClosing(inputImg, seShape, seSize)
% MORPHOLOGICALCLOSING Fills small interior holes, gaps, and cracks within motifs.
%
% Syntax:
%   closedImg = morphologicalClosing(inputImg, seShape, seSize)
%
% Inputs:
%   inputImg - Binary or grayscale image matrix.
%   seShape  - (Optional) Structuring element shape: 'disk', 'square', or 'diamond'. Default is 'disk'.
%   seSize   - (Optional) Radius or half-width of the structuring element. Default is 2.
%
% Outputs:
%   closedImg - Resulting image after dilation followed by erosion.
%
% Theory:
%   Morphological closing is defined as dilation followed by erosion by the same structuring element B:
%     A . B = (A (+) B) (-) B
%   In saree motif segmentation, closing welds gaps in intricate embroidery lines,
%   bridges tiny discontinuities in zari boundaries, and fuses adjacent motif elements into solid regions.

  if nargin < 1 || isempty(inputImg)
    error('morphologicalClosing: InvalidInput, input image is required.');
  endif

  if nargin < 2 || isempty(seShape)
    seShape = 'disk';
  endif

  if nargin < 3 || isempty(seSize)
    seSize = 2;
  endif

  % Ensure Octave image package is loaded
  if ~exist('imclose', 'file') && ~exist('imclose', 'builtin')
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

  closedImg = imclose(inputImg, se);

endfunction
