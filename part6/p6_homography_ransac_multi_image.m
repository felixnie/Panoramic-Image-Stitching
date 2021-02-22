% Part 6: Basic Panoramic Image
%
% There are 7 stages in this part. The time for running will be longer if
% larger interpolation parameters are chosen. The running progress will be
% updated in the command window.
% 
% 1. Load the 5 images and extract the discriptors
%    Function VL_SIFT is used in this script to extract keypoints and
%    descriptors. It's the only high-level function used in this part.
% 
% 2. Exhaustive search on matched descriptors
%    Find the best match between the keypoints in neighbouring images. This
%    part is placed in MY_MATCH function, which has exactly the same
%    functionality and output as the function VL_UBCMATCH from VLFeat.
% 
%    Also, I exactly followed the paper by David Lowe, by setting a
%    threshold to make sure only the pairs that satisfy the following
%    condition are accepted:
% 
%        THRESHOLD * CLOSEST_DISTANCE < SECOND_CLOSEST_DISTANCE
% 
%    Only the best descriptor pairs, which are significantly closer to each
%    other than to other descriptors, are accepted. The threshold is set to
%    1.5 by default, as mentioned in the paper Automatic Panoramic Image
%    Stitching Using Invariant Features.
% 
% 3. RANSAC
%    This part is placed in MY_RANSAC function. It outputs the best matches
%    and their inliers for the furthur calculation of homography matrix.
%    Some parameters can be changed in this part like iterations, epsilon
%    and the number of selected keypoints.
% 
% 4. Apply interpolation to the images
%    I chose img3 to be the canvas, which means that img2 and img4 should
%    be interpolated to a larger size, and img1 and img5 should be
%    interpolated to a much larger scale.
%    By setting the parameter vector SCALE we can achieve respective
%    scaling on each image. For example, the default SCALE is [8 4 1 4 8].
% 
% 5. Calculate homography matrices
%    The script in MY_HOMOGRAPHY function is used to compute H12, H23, H34
%    and H45. Then I plan to map img1, 2, 4, 5 directly to the canvas
%    (img3), so H13, H23, H43 and H53 are calculated.
% 
% 6. Prepare the canvas
% 
% 7. Stitching - Transform interpolated img1, 2, 4, 5 & stitch to img3
% 
% Please change rootpath to the project root path so that we can find the
% images and use the VLFeat libraries.
%

clear all
close all

% please change rootpath to the project root path
rootpath = 'C:\Users\nieht\EE5371 CA1';

% perform one-time setup of vlfeat
run([rootpath '\vlfeat-0.9.21\toolbox\vl_setup'])

% add path so that sift can find the images
addpath(rootpath)

% fix the seed to generate repeatable results
randn('state',0) ;
rand('state',0) ;

% load image
fprintf('Loading images... ')
img1 = imread('im01.jpg');
img2 = imread('im02.jpg');
img3 = imread('im03.jpg');
img4 = imread('im04.jpg');
img5 = imread('im05.jpg');
fprintf('Done.\n')

[h1,w1,depth1] = size(img1);
[h2,w2,depth2] = size(img2);
[h3,w3,depth3] = size(img3);
[h4,w4,depth4] = size(img4);
[h5,w5,depth5] = size(img5);

% extract keypoints and descriptors
fprintf('Extracting SIFT descriptors... ')
[f1,d1] = vl_sift(im2single(rgb2gray(img1)));
[f2,d2] = vl_sift(im2single(rgb2gray(img2)));
[f3,d3] = vl_sift(im2single(rgb2gray(img3)));
[f4,d4] = vl_sift(im2single(rgb2gray(img4)));
[f5,d5] = vl_sift(im2single(rgb2gray(img5)));
fprintf('Done.\n')

% tranform descriptors into double
d1 = double(d1);
d2 = double(d2);
d3 = double(d3);
d4 = double(d4);
d5 = double(d5);

% show matched images side by side
% if you need visualization, use 'disp'
% or you can turn off by setting 'none' to save some time
% threshold is set to 1.5 by default
fprintf('Matching descriptors... ')
[matches_12, scores_12] = my_match(img1, img2, f1, f2, d1, d2, 'disp', 1.5);
[matches_23, scores_23] = my_match(img2, img3, f2, f3, d2, d3, 'disp', 1.5);
[matches_34, scores_34] = my_match(img3, img4, f3, f4, d3, d4, 'disp', 1.5);
[matches_45, scores_45] = my_match(img4, img5, f4, f5, d4, d5, 'none', 1.5);
fprintf('Done.\n')


%% interpolation
fprintf('Interpolating... ')
scales = [8, 4, 1, 4, 8];
img1_interpolated = imresize(img1, scales(1), 'bicubic');
img2_interpolated = imresize(img2, scales(2), 'bicubic');
img3_interpolated = imresize(img3, scales(3), 'bicubic');
img4_interpolated = imresize(img4, scales(4), 'bicubic');
img5_interpolated = imresize(img5, scales(5), 'bicubic');

[h1,w1,depth1] = size(img1_interpolated);
[h2,w2,depth2] = size(img2_interpolated);
[h3,w3,depth3] = size(img3_interpolated); % img3 remains the same
[h4,w4,depth4] = size(img4_interpolated);
[h5,w5,depth5] = size(img5_interpolated);
fprintf('Done.\n')

%% ransac

n = 4;                          % randomly select n matches
iter = 200;                     % number of iterations
epsilon = 6^2;                  % ε

%% compute H12 H23 H34 H45
fprintf('Running RANSAC... ')
[inliers12_max, inliers12_X1, inliers12_X2, ~, ~, ~] ...
    = my_ransac(img1, img2, f1, f2, 'disp', matches_12, 5, 200, 6^2);

[inliers23_max, inliers23_X1, inliers23_X2, ~, ~, ~] ...
    = my_ransac(img2, img3, f2, f3, 'disp', matches_23, 5, 200, 6^2);

[inliers34_max, inliers34_X1, inliers34_X2, ~, ~, ~] ...
    = my_ransac(img3, img4, f3, f4, 'disp', matches_34, 5, 200, 6^2);

[inliers45_max, inliers45_X1, inliers45_X2, ~, ~, ~] ...
    = my_ransac(img4, img5, f4, f5, 'none', matches_45, 5, 200, 6^2);
fprintf('Done.\n')

fprintf('Calculating homography matrix... ')
m_12 = inliers12_X1(1,:) * scales(1);
n_12 = inliers12_X1(2,:) * scales(1);
p_12 = inliers12_X2(1,:) * scales(2);
q_12 = inliers12_X2(2,:) * scales(2);

m_23 = inliers23_X1(1,:) * scales(2);
n_23 = inliers23_X1(2,:) * scales(2);
p_23 = inliers23_X2(1,:) * scales(3);
q_23 = inliers23_X2(2,:) * scales(3);

m_34 = inliers34_X1(1,:) * scales(3);
n_34 = inliers34_X1(2,:) * scales(3);
p_34 = inliers34_X2(1,:) * scales(4);
q_34 = inliers34_X2(2,:) * scales(4);

m_45 = inliers45_X1(1,:) * scales(4);
n_45 = inliers45_X1(2,:) * scales(4);
p_45 = inliers45_X2(1,:) * scales(5);
q_45 = inliers45_X2(2,:) * scales(5);

H12 = my_homography(m_12, n_12, p_12, q_12, inliers12_max);
H23 = my_homography(m_23, n_23, p_23, q_23, inliers23_max);
H34 = my_homography(m_34, n_34, p_34, q_34, inliers34_max);
H45 = my_homography(m_45, n_45, p_45, q_45, inliers45_max);

H13 = H23 * H12;
H35 = H45 * H34;
H43 = pinv(H34);
H53 = pinv(H35);
fprintf('Done.\n')
%% check the lower/upper bound of transformed pixel coordinates
fprintf('Preparing canvas... ')
vertex1 = [1, 1, 1;     % top-left
           1, h1, 1;    % bottom-left
           w1, 1, 1;    % top-right
           w1, h1, 1]'; % bottom-right
vertex2 = [1, 1, 1; 1, h2, 1; w2, 1, 1; w2, h2, 1]';
vertex4 = [1, 1, 1; 1, h4, 1; w4, 1, 1; w4, h4, 1]';
vertex5 = [1, 1, 1; 1, h5, 1; w5, 1, 1; w5, h5, 1]';

%% stitching - transform INTERPOLATED img1 & stitch to img2
pos = []; % position of transformed vertices
pos = cat(2, pos, H13 * vertex1);
pos = cat(2, pos, H23 * vertex2);
pos = cat(2, pos, H43 * vertex4);
pos = cat(2, pos, H53 * vertex5);
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

col_min = min(col_min, 1);
row_min = min(row_min, 1);

% deploy canvas
canvas = zeros(row_max-row_min+1, col_max-col_min+1, depth1);
fprintf('Done.\n')

% pixel-wise copy on img3
fprintf('Copying img3... ')
for r = 1:h3
    for c = 1:w3
        col = c-col_min+1;
        row = r-row_min+1;
        canvas(row,col,:) = img3_interpolated(r,c,:);
    end
end
fprintf('Done.\n')

% pixel-wise transformation on img1
fprintf('Transfroming img1... ')
for r = 1:h1
    for c = 1:w1
        pos = H13 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas(row,col,:) = img1_interpolated(r,c,:);
    end
end
fprintf('Done.\n')

% pixel-wise transformation on img2
fprintf('Transfroming img2... ')
for r = 1:h2
    for c = 1:w2
        pos = H23 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas(row,col,:) = img2_interpolated(r,c,:);
    end
end
fprintf('Done.\n')

% pixel-wise transformation on img4
fprintf('Transfroming img4... ')
for r = 1:h4
    for c = 1:w4
        pos = H43 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas(row,col,:) = img4_interpolated(r,c,:);
    end
end
fprintf('Done.\n')

% pixel-wise transformation on img5
fprintf('Transfroming img5... ')
for r = 1:h5
    for c = 1:w5
        pos = H53 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas(row,col,:) = img5_interpolated(r,c,:);
    end
end
fprintf('Done.\n')

figure
imshow(uint8(canvas))
title('Transform Interpolated Image 1, 2, 4, 5 & Stitch to Image 3')
