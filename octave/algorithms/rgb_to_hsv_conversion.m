function [visualOutput, hChannel, sChannel, vChannel] = rgb_to_hsv_conversion(inputImg)
% RGB_TO_HSV_CONVERSION Converts RGB image to HSV color space with multi-channel visualization.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   The RGB color space mixes chromaticity and intensity in all three channels.
%   In contrast, the Cylindrical HSV model decouples color information into:
%     1. Hue (H in [0, 1] or 0-360 deg): Dominant spectral wavelength (pure color).
%     2. Saturation (S in [0, 1]): Color purity / dilution by white light.
%     3. Value (V in [0, 1]): Perceived brightness / intensity of the light source.
%
%   In saree motif segmentation, HSV is superior because variations in lighting,
%   folds, and shadows primarily change Value (V) while Hue (H) remains invariant.
%
% Visual Output:
%   Produces a comprehensive 2x2 educational visualization grid:
%     [ Panel 1: Original RGB          | Panel 2: Hue Spectrum (H, S=1, V=1) ]
%     [ Panel 3: Saturation Map (S)   | Panel 4: Value / Brightness Map (V)  ]
%
% Syntax:
%   [visualOutput, hChannel, sChannel, vChannel] = rgb_to_hsv_conversion(inputImg)

  if nargin < 1 || isempty(inputImg)
    error('rgb_to_hsv_conversion: Input image is required.');
  endif

  % Ensure RGB format
  [rows, cols, channels] = size(inputImg);
  if channels == 1
    rgb = repmat(inputImg, [1, 1, 3]);
  elseif channels >= 3
    rgb = inputImg(:, :, 1:3);
  else
    error('rgb_to_hsv_conversion: Image must have 1 or 3 channels.');
  endif

  % Normalize to double [0, 1]
  if isinteger(rgb)
    rgbNorm = double(rgb) / 255.0;
  else
    rgbNorm = double(rgb);
    if max(rgbNorm(:)) > 1.0
      rgbNorm = rgbNorm / 255.0;
    endif
  endif

  % Convert to HSV
  try
    hsv = rgb2hsv(rgbNorm);
  catch
    % Manual RGB to HSV conversion algorithm
    R = rgbNorm(:, :, 1);
    G = rgbNorm(:, :, 2);
    B = rgbNorm(:, :, 3);

    maxVal = max(rgbNorm, [], 3);
    minVal = min(rgbNorm, [], 3);
    delta = maxVal - minVal;

    % Value
    V = maxVal;

    % Saturation
    S = zeros(rows, cols);
    nonZeroV = V > 1e-6;
    S(nonZeroV) = delta(nonZeroV) ./ V(nonZeroV);

    % Hue
    H = zeros(rows, cols);
    maskR = (maxVal == R) & (delta > 1e-6);
    maskG = (maxVal == G) & (delta > 1e-6);
    maskB = (maxVal == B) & (delta > 1e-6);

    H(maskR) = mod((G(maskR) - B(maskR)) ./ delta(maskR), 6);
    H(maskG) = ((B(maskG) - R(maskG)) ./ delta(maskG)) + 2;
    H(maskB) = ((R(maskB) - G(maskB)) ./ delta(maskB)) + 4;
    H = H / 6.0; % Normalize to [0, 1]
    H(H < 0) = H(H < 0) + 1.0;

    hsv = cat(3, H, S, V);
  end_try_catch

  hChannel = hsv(:, :, 1);
  sChannel = hsv(:, :, 2);
  vChannel = hsv(:, :, 3);

  % 1. Panel 1: Original RGB
  panel1 = uint8(rgbNorm * 255.0);

  % 2. Panel 2: Hue visualized as full-saturation chromatic color spectrum
  hueOnlyHSV = cat(3, hChannel, ones(rows, cols), ones(rows, cols));
  try
    panel2 = uint8(hsv2rgb(hueOnlyHSV) * 255.0);
  catch
    panel2 = uint8(cat(3, hChannel * 255.0, (1 - hChannel) * 255.0, abs(0.5 - hChannel) * 510.0));
  end_try_catch

  % 3. Panel 3: Saturation Map (converted to 3-channel RGB for grid alignment)
  sMap = uint8(sChannel * 255.0);
  panel3 = cat(3, sMap, sMap, sMap);

  % 4. Panel 4: Value / Intensity Map (converted to 3-channel RGB for grid alignment)
  vMap = uint8(vChannel * 255.0);
  panel4 = cat(3, vMap, vMap, vMap);

  % Divider line (white border 4px)
  divCol = uint8(ones(rows, 4, 3) * 255);
  topRow = cat(2, panel1, divCol, panel2);
  bottomRow = cat(2, panel3, divCol, panel4);

  divRow = uint8(ones(4, size(topRow, 2), 3) * 255);
  visualOutput = cat(1, topRow, divRow, bottomRow);

endfunction
