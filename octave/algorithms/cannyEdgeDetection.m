function [edgeMap] = cannyEdgeDetection(inputImg, thresholds, sigma)
% CANNYEDGEDETECTION Detects motif boundaries using the multi-stage Canny algorithm.
%
% Syntax:
%   edgeMap = cannyEdgeDetection(inputImg, thresholds, sigma)
%
% Inputs:
%   inputImg   - Grayscale or RGB image.
%   thresholds - (Optional) 2-element vector [lowThresh highThresh] in [0, 1].
%                Default is automatic.
%   sigma      - (Optional) Standard deviation for Gaussian smoothing prior to gradient.
%                Default is sqrt(2).
%
% Outputs:
%   edgeMap    - Binary edge map (uint8, 0 or 255).
%
% Theory & Dependencies:
%   The Canny edge detector involves five fundamental steps:
%   1. Gaussian smoothing to reduce sensor and fabric noise.
%   2. Directional gradient computation (magnitude and orientation).
%   3. Non-maximum suppression along gradient normals for thin 1-pixel edges.
%   4. Double thresholding (strong and weak edge categorization).
%   5. Edge tracking by hysteresis (connecting weak edges to strong edges).
%
%   Requires: GNU Octave 'image' package (edge.m).

  if nargin < 1 || isempty(inputImg)
    error('cannyEdgeDetection: InvalidInput, input image is required.');
  endif

  % Convert to grayscale
  if size(inputImg, 3) >= 3
    gray = grayscale(inputImg);
  else
    gray = inputImg;
  endif

  grayDouble = double(gray) / 255.0;

  % Ensure Octave 'image' package is available
  if ~exist('edge', 'file') && ~exist('edge', 'builtin')
    warning('cannyEdgeDetection: Loading GNU Octave image package...');
    pkg load image;
  endif

  % Call Canny detector
  if nargin >= 3 && ~isempty(thresholds) && ~isempty(sigma)
    binaryEdges = edge(grayDouble, 'Canny', thresholds, sigma);
  elseif nargin >= 2 && ~isempty(thresholds)
    binaryEdges = edge(grayDouble, 'Canny', thresholds);
  else
    binaryEdges = edge(grayDouble, 'Canny');
  endif

  % Return 0 or 255 uint8 map
  edgeMap = uint8(binaryEdges * 255);

endfunction
