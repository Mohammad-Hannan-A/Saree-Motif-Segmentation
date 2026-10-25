function [compositeImg] = motif_compositing(destImg, motifRGB, motifAlpha, posX, posY, scale, angle, opacity, flipH, flipV, outputFilePath)
% MOTIF_COMPOSITING Seamlessly composites an extracted motif onto another image using Porter-Duff Alpha Over blending.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   Digital image compositing combines a foreground object F (motif) onto a background B (destination).
%   Under the classic Porter-Duff 'Over' compositing model:
%     C_{out}(x, y) = C_B(x, y) * (1 - \alpha_{eff}(x, y)) + C_F(x, y) * \alpha_{eff}(x, y)
%   where \alpha_{eff}(x, y) = (\alpha(x, y) / 255.0) * opacity.
%   Geometric Transformations:
%     1. Spatial Scaling: Resamples motif using bilinear interpolation by factor s.
%     2. Rotation: Rotates motif around its centroid by angle \theta degrees.
%     3. Spatial Translation & Clamping: Places motif at destination coordinates (posX, posY).
%
% Syntax:
%   compositeImg = motif_compositing(destImg, motifRGB, motifAlpha, posX, posY, scale, angle, opacity, flipH, flipV, outputFilePath)

  if nargin < 5
    error('motif_compositing: Destination image, motif RGB, alpha, posX, and posY are required.');
  endif
  if nargin < 6 || isempty(scale), scale = 1.0; endif
  if nargin < 7 || isempty(angle), angle = 0.0; endif
  if nargin < 8 || isempty(opacity), opacity = 1.0; endif
  if nargin < 9 || isempty(flipH), flipH = false; endif
  if nargin < 10 || isempty(flipV), flipV = false; endif
  if nargin < 11, outputFilePath = ''; endif

  % Forward to composeMotif engine
  compositeImg = composeMotif(destImg, motifRGB, motifAlpha, posX, posY, scale, angle, opacity, flipH, flipV, outputFilePath);

endfunction
