% generateSyntheticSamples.m
% Generates realistic synthetic saree images with traditional Indian decorative motifs
% (Paisley/Mango, Peacock, Floral Lotus) and plain destination garment fabrics.
%
% Usage:
%   octave-cli generateSyntheticSamples.m

clc;
clear all;

fprintf('Generating synthetic saree and garment sample images...\n');

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptDir)); % Go up from octave/scripts to Saree-Motif-Segmentation
samplesDir = fullfile(projectRoot, 'samples');
if ~exist(samplesDir, 'dir'), mkdir(samplesDir); endif

pkg load image;

% --- Sample 1: Maroon Silk Saree with Golden Zari Paisley (Mango/Kalka) Motif ---
H = 500; W = 500;
[X, Y] = meshgrid(1:W, 1:H);

% Fabric texture with fine weave simulation
weave = 10 * sin(X * 0.5) .* cos(Y * 0.5);
maroon = zeros(H, W, 3, 'uint8');
maroon(:, :, 1) = uint8(max(0, min(255, 128 + weave))); % Rich maroon
maroon(:, :, 2) = uint8(max(0, min(255, 12 + weave*0.2)));
maroon(:, :, 3) = uint8(max(0, min(255, 38 + weave*0.3)));

% Gold Zari Paisley shape in center
% Teardrop body
bodyDist = ((X - 250) / 70).^2 + ((Y - 280) / 100).^2;
% Curving swirl head
headDist = ((X - 290) / 45).^2 + ((Y - 180) / 60).^2;
% Decorative inner eye
innerDist = ((X - 250) / 35).^2 + ((Y - 275) / 50).^2;

paisleyMask = (bodyDist <= 1.0 | headDist <= 1.0) & (innerDist > 0.4);
% Inner eye center dot
eyeDot = (innerDist <= 0.15);
paisleyMask = paisleyMask | eyeDot;

% Border pattern on right
borderMask = (X >= 440 & X <= 480);
chevron = mod(Y + X, 20) < 10;
borderPattern = borderMask & chevron;

for c = 1:3
  ch = maroon(:, :, c);
  % Golden zari color [225, 180, 45]
  if c == 1, ch(paisleyMask | borderPattern) = 225; endif
  if c == 2, ch(paisleyMask | borderPattern) = 180; endif
  if c == 3, ch(paisleyMask | borderPattern) = 45;  endif
  maroon(:, :, c) = ch;
endfor

imwrite(maroon, fullfile(samplesDir, 'saree_paisley_maroon.png'));
fprintf('  Created: samples/saree_paisley_maroon.png\n');

% --- Sample 2: Royal Blue Silk Saree with Peacock Motif ---
blueSaree = zeros(H, W, 3, 'uint8');
blueSaree(:, :, 1) = uint8(max(0, min(255, 18 + weave*0.3)));
blueSaree(:, :, 2) = uint8(max(0, min(255, 35 + weave*0.5)));
blueSaree(:, :, 3) = uint8(max(0, min(255, 120 + weave)));

% Peacock body (slender neck and head)
neckDist = ((X - 230) / 25).^2 + ((Y - 200) / 60).^2;
headDist = ((X - 240) / 20).^2 + ((Y - 140) / 20).^2;
bodyDist = ((X - 220) / 50).^2 + ((Y - 280) / 70).^2;
beak = (X >= 255 & X <= 275 & abs(Y - 140) <= (275 - X) * 0.4);

% Fan of ornate peacock feathers radiating backwards
theta = atan2(Y - 260, X - 180);
r = sqrt((X - 180).^2 + (Y - 260).^2);
feathers = (r >= 60 & r <= 170 & theta >= -2.8 & theta <= -0.4);
featherEyes = feathers & (mod(r, 35) < 18) & (mod(theta * 10, 3) < 1.5);

peacockMain = (neckDist <= 1.0 | headDist <= 1.0 | bodyDist <= 1.0 | beak);

for c = 1:3
  ch = blueSaree(:, :, c);
  % Gold zari highlights on peacock neck and feathers
  if c == 1
    ch(peacockMain) = 40;
    ch(feathers) = 30;
    ch(featherEyes) = 220;
  endif
  if c == 2
    ch(peacockMain) = 160; % Emerald green/cyan peacock body
    ch(feathers) = 140;
    ch(featherEyes) = 175;
  endif
  if c == 3
    ch(peacockMain) = 170;
    ch(feathers) = 80;
    ch(featherEyes) = 40;  % Gold eyes in feathers
  endif
  blueSaree(:, :, c) = ch;
endfor

imwrite(blueSaree, fullfile(samplesDir, 'saree_peacock_royal_blue.png'));
fprintf('  Created: samples/saree_peacock_royal_blue.png\n');

% --- Sample 3: Emerald Green Silk Saree with Floral Lotus Motif ---
emeraldSaree = zeros(H, W, 3, 'uint8');
emeraldSaree(:, :, 1) = uint8(max(0, min(255, 15 + weave*0.2)));
emeraldSaree(:, :, 2) = uint8(max(0, min(255, 95 + weave)));
emeraldSaree(:, :, 3) = uint8(max(0, min(255, 50 + weave*0.4)));

% Lotus petals centered at (250, 250)
petal1 = (((X - 250) * cos(0) - (Y - 250) * sin(0)) / 25).^2 + ...
         (((X - 250) * sin(0) + (Y - 250) * cos(0)) / 60).^2 <= 1.0;
petal2 = (((X - 250) * cos(pi/4) - (Y - 250) * sin(pi/4)) / 25).^2 + ...
         (((X - 250) * sin(pi/4) + (Y - 250) * cos(pi/4)) / 60).^2 <= 1.0;
petal3 = (((X - 250) * cos(-pi/4) - (Y - 250) * sin(-pi/4)) / 25).^2 + ...
         (((X - 250) * sin(-pi/4) + (Y - 250) * cos(-pi/4)) / 60).^2 <= 1.0;
petal4 = (((X - 250) * cos(pi/2) - (Y - 250) * sin(pi/2)) / 25).^2 + ...
         (((X - 250) * sin(pi/2) + (Y - 250) * cos(pi/2)) / 60).^2 <= 1.0;
petalCenter = ((X - 250).^2 + (Y - 250).^2) <= 18^2;

lotusMotif = petal1 | petal2 | petal3 | petal4 | petalCenter;

for c = 1:3
  ch = emeraldSaree(:, :, c);
  if c == 1, ch(lotusMotif) = 240; endif % Pink/Gold lotus zari
  if c == 2, ch(lotusMotif) = 195; endif
  if c == 3, ch(lotusMotif) = 60;  endif
  emeraldSaree(:, :, c) = ch;
endfor

imwrite(emeraldSaree, fullfile(samplesDir, 'saree_floral_emerald.png'));
fprintf('  Created: samples/saree_floral_emerald.png\n');

% --- Sample 4: Destination Plain Mustard Kurti Garment Fabric ---
mustardGarment = zeros(600, 600, 3, 'uint8');
[Xg, Yg] = meshgrid(1:600, 1:600);
garmentWeave = 8 * sin(Xg * 0.3) .* cos(Yg * 0.3);
% Soft garment drape fold gradient
drape = 20 * sin(Xg / 80);

mustardGarment(:, :, 1) = uint8(max(0, min(255, 225 + garmentWeave + drape)));
mustardGarment(:, :, 2) = uint8(max(0, min(255, 175 + garmentWeave*0.8 + drape*0.8)));
mustardGarment(:, :, 3) = uint8(max(0, min(255, 65 + garmentWeave*0.4 + drape*0.4)));

imwrite(mustardGarment, fullfile(samplesDir, 'destination_kurti_mustard.png'));
fprintf('  Created: samples/destination_kurti_mustard.png\n');

% --- Sample 5: Destination Elegant Ivory Silk Blouse Garment ---
ivoryGarment = zeros(600, 600, 3, 'uint8');
ivoryGarment(:, :, 1) = uint8(max(0, min(255, 248 + garmentWeave + drape)));
ivoryGarment(:, :, 2) = uint8(max(0, min(255, 245 + garmentWeave + drape)));
ivoryGarment(:, :, 3) = uint8(max(0, min(255, 235 + garmentWeave + drape)));

imwrite(ivoryGarment, fullfile(samplesDir, 'destination_blouse_ivory.png'));
fprintf('  Created: samples/destination_blouse_ivory.png\n');

fprintf('All synthetic sample images generated successfully!\n');
