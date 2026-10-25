function [croppedImg, actualBbox] = bounding_box_crop(inputImg, bbox)
% BOUNDING_BOX_CROP Crops strictly the specified rectangular Region of Interest (ROI).
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Spatial bounding box cropping restricts subsequent motif extraction or feature analysis
%   to a localized user-selected rectangle [x, y, width, height].
%   Coordinates are clamped safely to image boundaries to prevent out-of-bounds array access.
%   In Bounding Box Mode, the output is strictly the cropped rectangular matrix, NOT the full image.
%
% Syntax:
%   [croppedImg, actualBbox] = bounding_box_crop(inputImg, bbox)
%
% Inputs:
%   inputImg   - RGB or grayscale image.
%   bbox       - 4-element vector [x, y, width, height] (1-indexed or 0-indexed).
%
% Outputs:
%   croppedImg - Submatrix image of size [actualHeight x actualWidth x channels].
%   actualBbox - 4-element vector of exact clamped bounds [x1, y1, width, height].

  if nargin < 1 || isempty(inputImg)
    error('bounding_box_crop: Input image is required.');
  endif

  [H, W, channels] = size(inputImg);

  if nargin < 2 || isempty(bbox) || length(bbox) < 4
    % Default: Center 60% crop
    x = round(W * 0.2);
    y = round(H * 0.2);
    w = round(W * 0.6);
    h = round(H * 0.6);
  else
    x = round(bbox(1));
    y = round(bbox(2));
    w = round(bbox(3));
    h = round(bbox(4));
  endif

  % Handle 0-indexed frontend coordinates (convert to 1-indexed for Octave)
  if x < 1, x = 1; endif
  if y < 1, y = 1; endif

  x1 = max(1, min(W, x));
  y1 = max(1, min(H, y));
  x2 = max(x1, min(W, x1 + max(1, w) - 1));
  y2 = max(y1, min(H, y1 + max(1, h) - 1));

  % Crop strictly
  croppedImg = inputImg(y1:y2, x1:x2, :);
  actualBbox = [x1, y1, (x2 - x1 + 1), (y2 - y1 + 1)];

endfunction
