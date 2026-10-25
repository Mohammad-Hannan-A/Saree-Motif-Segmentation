% main.m
% GNU Octave Standalone Testing & Diagnostic Entry Point
% Saree Motif Segmentation Project
%
% How to run:
%   From Octave GUI: Open this file and click 'Run' (F5).
%   From CLI:        octave-cli main.m

clc;
clear all;
close all;

fprintf('====================================================\n');
fprintf('  SAREE MOTIF SEGMENTATION - GNU OCTAVE ENGINE\n');
fprintf('====================================================\n\n');

% 1. Environment & Package Verification
fprintf('[1/4] Verifying GNU Octave Environment & Packages...\n');
fprintf('      Octave Version: %s\n', version());

hasImagePkg = false;
try
  pkg load image;
  hasImagePkg = true;
  fprintf('      [SUCCESS] GNU Octave ''image'' package loaded successfully.\n');
catch err
  fprintf('      [WARNING] ''image'' package could not be loaded: %s\n', err.message);
  fprintf('      To install, run in Octave: pkg install -forge image\n');
end_try_catch

% 2. Path Setup
fprintf('\n[2/4] Configuring Algorithm Search Paths...\n');
scriptDir = fileparts(mfilename('fullpath'));
algoDir = fullfile(scriptDir, 'algorithms');
if exist(algoDir, 'dir')
  addpath(algoDir);
  fprintf('      [SUCCESS] Added algorithm path: %s\n', algoDir);
else
  error('      [ERROR] Algorithms directory not found at: %s', algoDir);
endif

% 3. Check Essential Functions
fprintf('\n[3/4] Checking Required Algorithm Functions...\n');
requiredFuncs = {
  'grayscale', 'imageNegative', 'binaryThreshold', 'adaptiveThreshold', ...
  'gaussianFilter', 'medianFilter', 'sharpenImage', 'contrastEnhancement', ...
  'histogramEqualization', 'cannyEdgeDetection', 'sobelEdgeDetection', ...
  'morphologicalErosion', 'morphologicalDilation', 'morphologicalOpening', ...
  'morphologicalClosing', 'colorSegmentation', 'contourDetection', ...
  'segmentMotif', 'refineMotifMask', 'extractTransparentMotif', 'composeMotif'
};

allFound = true;
for k = 1:numel(requiredFuncs)
  fnName = requiredFuncs{k};
  if exist(fnName, 'file') == 2
    fprintf('      [OK] %-25s found\n', fnName);
  else
    fprintf('      [MISSING] %-25s NOT found\n', fnName);
    allFound = false;
  endif
endfor

if allFound
  fprintf('\n      All 21 image-processing algorithms are verified and ready!\n');
else
  error('\n      One or more algorithm functions are missing. Please check the algorithms directory.');
endif

% 4. Quick Self-Test with Synthetic Saree Pattern
fprintf('\n[4/4] Running Quick Diagnostic Self-Test...\n');
% Generate 100x100 synthetic saree patch: Dark maroon background [128, 0, 32] with gold paisley motif [218, 165, 32]
H = 120; W = 120;
testImg = zeros(H, W, 3, 'uint8');
testImg(:, :, 1) = 128; % Maroon
testImg(:, :, 2) = 10;
testImg(:, :, 3) = 35;

% Add circular golden motif in center
[X, Y] = meshgrid(1:W, 1:H);
distFromCenter = sqrt((X - 60).^2 + (Y - 60).^2);
motifMask = (distFromCenter <= 30);

for c = 1:3
  ch = testImg(:, :, c);
  if c == 1, ch(motifMask) = 218; endif % Gold R
  if c == 2, ch(motifMask) = 165; endif % Gold G
  if c == 3, ch(motifMask) = 32;  endif % Gold B
  testImg(:, :, c) = ch;
endfor

% Test grayscale
grayTest = grayscale(testImg);
assert(size(grayTest, 1) == H && size(grayTest, 2) == W, 'Grayscale test failed size assertion');

% Test binary threshold
binTest = binaryThreshold(testImg, -1);
assert(max(binTest(:)) == 255, 'Binary threshold test failed max value assertion');

% Test extraction
[cropRGB, cropAlpha, bbox] = extractTransparentMotif(testImg, binTest);
assert(size(cropRGB, 3) == 3, 'Extraction RGB channels test failed');
assert(size(cropAlpha, 1) > 0, 'Extraction Alpha channel test failed');

% Test composition
destBg = 200 * ones(150, 150, 3, 'uint8'); % Light destination silk
composite = composeMotif(destBg, cropRGB, cropAlpha, 20, 20, 1.0, 0, 0.9, false, false);
assert(size(composite, 1) == 150 && size(composite, 2) == 150, 'Composition dimension test failed');

fprintf('      [SUCCESS] Quick diagnostic pipeline passed without errors!\n\n');
fprintf('====================================================\n');
fprintf('  SYSTEM READY FOR BACKEND & FRONTEND INTEGRATION\n');
fprintf('====================================================\n');
fprintf('  To launch backend:\n');
fprintf('    1. Open terminal in "backend" directory\n');
fprintf('    2. Run: npm install\n');
fprintf('    3. Run: npm start\n');
fprintf('  Then open your browser to the URL shown by the server.\n\n');
