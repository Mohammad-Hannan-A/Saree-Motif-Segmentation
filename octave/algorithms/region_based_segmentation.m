function [segmentedImg, regionMask] = region_based_segmentation(inputImg, seedPoint, tolerance)
% REGION_BASED_SEGMENTATION Region-growing segmentation based on spatial connectivity and pixel similarity.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory & Academic Assumptions:
%   Assumption:
%     The saree motif forms a spatially coherent, connected set of pixels whose photometric
%     intensities (or chromatic signatures) vary smoothly below an homogeneity threshold.
%
%   Algorithm (4-Connected Seeded Region Growing):
%     1. A seed pixel S = (x_0, y_0) is selected (defaults to image center or user coordinate).
%     2. The algorithm inspects the 4-connected spatial neighbors of currently accepted region pixels.
%     3. If |I(x, y) - I(seed)| <= tolerance (or difference from running region mean),
%        the neighbor is merged into the region.
%     4. Iteration continues via a breadth-first search (BFS) queue until the boundary is reached.
%
% Syntax:
%   [segmentedImg, regionMask] = region_based_segmentation(inputImg, seedPoint, tolerance)
%
% Inputs:
%   inputImg   - RGB [M x N x 3] or grayscale [M x N] image.
%   seedPoint  - [x, y] coordinates in [1..W, 1..H] (default: [round(W/2), round(H/2)]).
%   tolerance  - Intensity distance threshold (default: 35, range: 5 to 100).
%
% Outputs:
%   segmentedImg - Original image with the segmented connected region highlighted in vivid color overlay.
%   regionMask   - Binary logical mask [M x N] indicating the grown region.

  if nargin < 1 || isempty(inputImg)
    error('region_based_segmentation: Input image is required.');
  endif

  [rows, cols, channels] = size(inputImg);

  if nargin < 2 || isempty(seedPoint) || length(seedPoint) < 2
    seedPoint = [round(cols / 2), round(rows / 2)];
  endif
  if nargin < 3 || isempty(tolerance) || tolerance <= 0
    tolerance = 35;
  endif

  seedX = min(cols, max(1, round(seedPoint(1))));
  seedY = min(rows, max(1, round(seedPoint(2))));

  % Work with luminance or intensity
  if channels >= 3
    intensity = 0.2989 * double(inputImg(:, :, 1)) + ...
                0.5870 * double(inputImg(:, :, 2)) + ...
                0.1140 * double(inputImg(:, :, 3));
    seedVal = double(inputImg(seedY, seedX, 1:3));
  else
    intensity = double(inputImg);
    seedVal = double(inputImg(seedY, seedX));
  endif

  % Preallocate logical mask and visited array
  regionMask = false(rows, cols);
  visited = false(rows, cols);

  % Breadth-first search queue for 4-connected region growing
  % We store linear indices for efficiency in Octave
  queue = zeros(rows * cols, 1);
  qHead = 1;
  qTail = 1;

  startIdx = sub2ind([rows, cols], seedY, seedX);
  queue(qTail) = startIdx;
  visited(seedY, seedX) = true;
  regionMask(seedY, seedX) = true;

  % Running region mean
  runningSum = double(inputImg(seedY, seedX, :));
  pixelCount = 1;

  % 4-neighbor directional offsets [dy, dx]
  dRow = [-1, 1, 0, 0];
  dCol = [0, 0, -1, 1];

  while qHead <= qTail
    currIdx = queue(qHead);
    qHead = qHead + 1;

    [cY, cX] = ind2sub([rows, cols], currIdx);

    for d = 1:4
      nY = cY + dRow(d);
      nX = cX + dCol(d);

      if nY >= 1 && nY <= rows && nX >= 1 && nX <= cols
        if ~visited(nY, nX)
          visited(nY, nX) = true;

          % Check distance to seed or running mean
          if channels >= 3
            neighborColor = double(inputImg(nY, nX, 1:3));
            dist = norm(neighborColor(:) - seedVal(:));
          else
            dist = abs(intensity(nY, nX) - intensity(seedY, seedX));
          endif

          if dist <= tolerance
            regionMask(nY, nX) = true;
            qTail = qTail + 1;
            queue(qTail) = sub2ind([rows, cols], nY, nX);
            pixelCount = pixelCount + 1;
          endif
        endif
      endif
    endfor

    % Safety cap to prevent runaway queue in huge flat images
    if pixelCount > (rows * cols * 0.95)
      break;
    endif
  endwhile

  % Generate visual overlay: tint segmented region in golden-cyan highlight
  if channels == 1
    rgbBase = repmat(uint8(inputImg), [1, 1, 3]);
  else
    rgbBase = uint8(inputImg(:, :, 1:3));
  endif

  segmentedImg = rgbBase;
  % Highlight segmented region in vibrant emerald/gold overlay
  overlayR = rgbBase(:, :, 1);
  overlayG = rgbBase(:, :, 2);
  overlayB = rgbBase(:, :, 3);

  overlayR(regionMask) = uint8(double(overlayR(regionMask)) * 0.4 + 255 * 0.6);
  overlayG(regionMask) = uint8(double(overlayG(regionMask)) * 0.4 + 215 * 0.6);
  overlayB(regionMask) = uint8(double(overlayB(regionMask)) * 0.4 + 0 * 0.6);

  segmentedImg(:, :, 1) = overlayR;
  segmentedImg(:, :, 2) = overlayG;
  segmentedImg(:, :, 3) = overlayB;

endfunction
