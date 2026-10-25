function [refinedMask] = refineMotifMask(inputMask, operations, params)
% REFINEMOTIFMASK Applies post-processing morphological operations to refine motif segmentation masks.
%
% Syntax:
%   refinedMask = refineMotifMask(inputMask, operations, params)
%
% Inputs:
%   inputMask  - Binary mask (uint8: 0 or 255, or logical).
%   operations - (Optional) Cell array of operation strings in execution order, or single string:
%                'fill_holes'   - Fills enclosed voids inside solid motifs (imfill)
%                'remove_noise' - Removes small disconnected specks (bwareaopen)
%                'smooth'       - Smooths jagged boundaries using opening and closing
%                'dilate'       - Slightly expands motif boundaries
%                'erode'        - Slightly shrinks motif boundaries
%                Default is {'fill_holes', 'remove_noise', 'smooth'}.
%   params     - (Optional) Struct of parameters:
%                .minArea - Minimum pixel area for noise removal (default: 50).
%                .seSize  - Structuring element radius (default: 2).
%
% Outputs:
%   refinedMask - Refined binary mask (uint8, 0 or 255).
%
% Theory:
%   Raw binarization of complex textile textures often suffers from interior voids
%   (due to thread weaving patterns) and salt-and-pepper noise from background cloth luster.
%   Refining the mask ensures solid, aesthetically intact motifs ready for extraction and composition.

  if nargin < 1 || isempty(inputMask)
    error('refineMotifMask: InvalidInput, input mask is required.');
  endif

  if nargin < 2 || isempty(operations)
    operations = {'fill_holes', 'remove_noise', 'smooth'};
  elseif ischar(operations)
    operations = {operations};
  endif

  if nargin < 3 || isempty(params)
    params = struct();
  endif

  minArea = 50;
  if isfield(params, 'minArea') && ~isempty(params.minArea)
    minArea = params.minArea;
  endif

  seSize = 2;
  if isfield(params, 'seSize') && ~isempty(params.seSize)
    seSize = params.seSize;
  endif

  % Ensure Octave image package is loaded
  if ~exist('imfill', 'file') && ~exist('imfill', 'builtin')
    pkg load image;
  endif

  currentLogical = (inputMask > 0);

  for k = 1:numel(operations)
    op = lower(operations{k});

    switch op
      case 'fill_holes'
        if exist('imfill', 'file') || exist('imfill', 'builtin')
          currentLogical = imfill(currentLogical, 'holes');
        endif

      case 'remove_noise'
        if exist('bwareaopen', 'file') || exist('bwareaopen', 'builtin')
          currentLogical = bwareaopen(currentLogical, minArea);
        else
          [labeled, numLabels] = bwlabel(currentLogical);
          if numLabels > 0
            props = regionprops(labeled, 'Area');
            valid = find([props.Area] >= minArea);
            currentLogical = ismember(labeled, valid);
          endif
        endif

      case 'smooth'
        se = strel('disk', max(1, round(seSize)), 0);
        % Opening then Closing for boundary regularization
        opened = imopen(currentLogical, se);
        currentLogical = imclose(opened, se);

      case 'dilate'
        se = strel('disk', max(1, round(seSize)), 0);
        currentLogical = imdilate(currentLogical, se);

      case 'erode'
        se = strel('disk', max(1, round(seSize)), 0);
        currentLogical = imerode(currentLogical, se);

      otherwise
        warning(['refineMotifMask: Unknown operation ''' op ''', skipped.']);
    endswitch
  endfor

  refinedMask = uint8(currentLogical * 255);

endfunction
