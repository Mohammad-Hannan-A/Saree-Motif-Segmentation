function [resizedImg] = image_resizing(inputImg, targetWidth, targetHeight, preserveAspect)
% IMAGE_RESIZING Scales an image to target dimensions with optional aspect ratio preservation.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Image resizing (spatial scaling) resamples continuous or discrete 2D spatial coordinate grids.
%   Bilinear interpolation computes each new pixel value as a weighted average of its 4 nearest neighbors:
%     f(x, y) = (1-dx)(1-dy)f(x1,y1) + dx(1-dy)f(x2,y1) + (1-dx)dy f(x1,y2) + dx dy f(x2,y2)
%   Preserving aspect ratio prevents geometric distortion of motifs (e.g., circular paisleys becoming oblong).
%
% Syntax:
%   resizedImg = image_resizing(inputImg, targetWidth, targetHeight, preserveAspect)
%
% Inputs:
%   inputImg       - RGB or grayscale image.
%   targetWidth    - Desired width in pixels (positive integer).
%   targetHeight   - Desired height in pixels (positive integer).
%   preserveAspect - Boolean (default: true). If true, fits image within bounding dimensions.
%
% Outputs:
%   resizedImg     - Scaled image.

  if nargin < 1 || isempty(inputImg)
    error('image_resizing: Input image is required.');
  endif

  [origH, origW, channels] = size(inputImg);

  if nargin < 2 || isempty(targetWidth) || targetWidth <= 0
    targetWidth = round(origW * 0.75);
  endif
  if nargin < 3 || isempty(targetHeight) || targetHeight <= 0
    targetHeight = round(origH * 0.75);
  endif
  if nargin < 4 || isempty(preserveAspect)
    preserveAspect = true;
  endif

  targetWidth = round(double(targetWidth));
  targetHeight = round(double(targetHeight));

  if preserveAspect
    scaleW = targetWidth / origW;
    scaleH = targetHeight / origH;
    scale = min(scaleW, scaleH);
    finalW = max(1, round(origW * scale));
    finalH = max(1, round(origH * scale));
  else
    finalW = max(1, targetWidth);
    finalH = max(1, targetHeight);
  endif

  % Use Octave imresize or fallback to bilinear interpolation grid
  try
    resizedImg = imresize(inputImg, [finalH, finalW], 'bilinear');
  catch
    % Manual Bilinear Interpolation fallback
    [X, Y] = meshgrid(linspace(1, origW, finalW), linspace(1, origH, finalH));
    resizedImg = zeros(finalH, finalW, channels, class(inputImg));
    for c = 1:channels
      plane = double(inputImg(:, :, c));
      interpPlane = interp2(1:origW, (1:origH)', plane, X, Y, 'linear');
      if isinteger(inputImg)
        resizedImg(:, :, c) = cast(round(interpPlane), class(inputImg));
      else
        resizedImg(:, :, c) = interpPlane;
      endif
    endfor
  end_try_catch

endfunction
