function [segmentedImg, clusterLabels, centroids] = kmeans_segmentation(inputImg, numClusters, maxIterations)
% KMEANS_SEGMENTATION Unsupervised pixel color clustering into K distinct chromatic classes.
% Academic Project: Saree Motif Segmentation Using Image Processing
%
% Theory:
%   K-Means partitions N pixel feature vectors {x_1, ..., x_N} into K clusters S = {S_1, ..., S_K}
%   to minimize within-cluster sum of squares (WCSS / variance):
%     arg min_S sum_{i=1}^K sum_{x in S_i} || x - mu_i ||^2
%   where mu_i is the centroid mean vector of cluster S_i.
%
%   In saree motif segmentation, K-Means groups pixels with similar color shades
%   (e.g., silk body background, golden zari embroidery, and shadow tones) into distinct
%   discrete regions without needing prior training.
%
% Syntax:
%   [segmentedImg, clusterLabels, centroids] = kmeans_segmentation(inputImg, numClusters, maxIterations)
%
% Inputs:
%   inputImg      - RGB [M x N x 3] or grayscale [M x N] image.
%   numClusters   - Integer K (default: 3, typical range: 2 to 8).
%   maxIterations - Maximum Lloyd iterations (default: 15).
%
% Outputs:
%   segmentedImg  - Image where each pixel is assigned its cluster centroid's RGB color.
%   clusterLabels - Matrix [M x N] with cluster index (1 to K) for each pixel.
%   centroids     - Matrix [K x Channels] of final centroid colors.

  if nargin < 1 || isempty(inputImg)
    error('kmeans_segmentation: Input image is required.');
  endif
  if nargin < 2 || isempty(numClusters) || numClusters < 2
    numClusters = 3;
  endif
  if nargin < 3 || isempty(maxIterations) || maxIterations < 1
    maxIterations = 15;
  endif

  numClusters = min(16, max(2, round(numClusters)));
  [rows, cols, channels] = size(inputImg);
  N = rows * cols;

  % Reshape pixel data to [N x channels] double matrix in [0, 255]
  data = double(reshape(inputImg, [N, channels]));

  % Initialize centroids using uniform quantile sampling for deterministic reproducibility
  sampleIndices = round(linspace(1, N, numClusters));
  centroids = data(sampleIndices, :);

  % Add small random perturbation to avoid duplicate identical centroids
  centroids = centroids + rand(size(centroids)) * 0.1;

  labels = zeros(N, 1);

  % Lloyd's Iterative Optimization Algorithm
  for iter = 1:maxIterations
    % 1. Compute Euclidean distance from every pixel to each centroid
    dists = zeros(N, numClusters);
    for k = 1:numClusters
      diffK = data - repmat(centroids(k, :), [N, 1]);
      dists(:, k) = sum(diffK.^2, 2);
    endfor

    % 2. Assign each pixel to nearest centroid
    [~, newLabels] = min(dists, [], 2);

    % Check for convergence
    if iter > 1 && isequal(newLabels, labels)
      break;
    endif
    labels = newLabels;

    % 3. Recompute centroid positions as mean of assigned pixels
    for k = 1:numClusters
      members = (labels == k);
      if any(members)
        centroids(k, :) = mean(data(members, :), 1);
      else
        % Re-seed empty cluster with random sample
        randIdx = randi(N);
        centroids(k, :) = data(randIdx, :);
      endif
    endfor
  endfor

  % Reconstruct segmented image by replacing pixels with centroid color
  segmentedData = zeros(N, channels);
  for k = 1:numClusters
    members = (labels == k);
    segmentedData(members, :) = repmat(centroids(k, :), [sum(members), 1]);
  endfor

  segmentedImg = uint8(reshape(segmentedData, [rows, cols, channels]));
  clusterLabels = uint8(reshape(labels, [rows, cols]));

endfunction
