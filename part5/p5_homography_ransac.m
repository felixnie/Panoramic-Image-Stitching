% Part 5: Homography + RANSAC
%
% There are 9 stages in this part. The time for running is ~60s.
% 
% It can be written in a more compact way by packaging each parts into 
% functions, like I did in part 6. But here I chose to make it detailed,
% making all the processes and variables visible.
% 
% 1. Load the images and extract the discriptors
%    Function VL_SIFT is used in this script to extract keypoints and
%    descriptors. It's the only high-level function used in this part.
% 
% 2. Exhaustive search on matched descriptors
%    Find the best match between the keypoints in both images. This has
%    exactly the same functionality and output as the function VL_UBCMATCH.
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
% 3. Show the keypoint pairs before RANSAC
% 
% 4. RANSAC
%    Some parameters can be changed in this part like iterations, epsilon
%    and the number of selected keypoints.
% 
% 5. Show the keypoint pairs after RANSAC
% 
% 6. Stitching - transform img1 & stitch to img2
% 
% 7. Stitching - transform img2 & stitch to img1
% 
% 8. Stitching - transform interpolated img1 & stitch to img2
% 
% 9. Stitching - transform interpolated img2 & stitch to img1
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
img1 = imread('im01.jpg');
img2 = imread('im02.jpg');
[h1,w1,depth1] = size(img1);
[h2,w2,depth2] = size(img2);

% extract keypoints and descriptors
[f1,d1] = vl_sift(im2single(rgb2gray(img1)));
[f2,d2] = vl_sift(im2single(rgb2gray(img2)));

% tranform descriptors into double
d1 = double(d1);
d2 = double(d2);


%% exhaustive search on matched descriptors

matches = [];
scores = [];
threshold = 1.5;
for i = 1:size(d1,2)
    closest_dist = Inf;
    second_closest_dist = Inf;
    best_match = 0;
    for j = 1:size(d2,2)
        % squared Euclidean distance
        d = d1(:,i) - d2(:,j);
        squared_dist = sum(d.^2);
        if squared_dist < closest_dist
            second_closest_dist = closest_dist;
            closest_dist = squared_dist;
            best_match = j;
        elseif squared_dist < second_closest_dist
            second_closest_dist = squared_dist;
        end
    end
    if threshold * closest_dist < second_closest_dist && best_match ~= 0
        matches = [matches [i best_match]'];
        scores = [scores closest_dist];
    end
end


%% display

[drop, perm] = sort(scores, 'descend') ;
matches = matches(:, perm) ;
scores  = scores(perm) ;

figure(1)
clf
imagesc(cat(2, img1, img2))
axis image off
title('Original Images')

x1 = f1(1,matches(1,:));
x2 = f2(1,matches(2,:)) + size(img1,2);
y1 = f1(2,matches(1,:));
y2 = f2(2,matches(2,:));

figure(2)
clf
imagesc(cat(2, img1, img2))
hold on
h = line([x1; x2], [y1; y2]);
set(h,'linewidth', 1)
axis image off
title('Matched Keypoints')


%% ransac

X1 = f1(1:2,matches(1,:));
X1(3,:) = 1;
X2 = f2(1:2,matches(2,:));
X2(3,:) = 1;                    % keypoints in Homogeneous coordinate

num_matches = size(matches,2);  % number of matches
n = 4;                          % randomly select n matches
iter = 200;                     % number of iterations
epsilon = 6^2;                  % ε
inliers = zeros(1,iter);        % number of inliers
inliers_max = 0;                % maximum of inliers

for t = 1:iter
    subset = randperm(num_matches, n);
    x1 = X1(1,subset);
    y1 = X1(2,subset);
    x2 = X2(1,subset);
    y2 = X2(2,subset);
    
    % calculate H12 in [x2,y2,1] = H12 * [x1,y1,1]
    % construct matrix A in Ah = 0
    A = [];
    for i = 1:n
        a = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
             0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i);];
%              -x1(i)*y2(i), -y1(i)*y2(i), -y2(i), x1(i)*x2(i), y1(i)*x2(i), x2(i), 0, 0, 0];
        A = cat(1, A, a);
    end

    % compute SVD over A & form H
    [U,S,V] = svd(A); % A = U*S*V'
    h = V(:,end);
    H12 = reshape(h,[3,3])';

    X2_transform = H12 * X1;
    dx = X2_transform(1,:)./X2_transform(3,:) - X2(1,:)./X2(3,:);
    dy = X2_transform(2,:)./X2_transform(3,:) - X2(2,:)./X2(3,:);
    inliers_flag = (dx.*dx + dy.*dy) < epsilon;
    inliers_num = sum(inliers_flag);
    if inliers_num > inliers_max
        inliers_max = inliers_num;
        inliers_X1 = X1(:, inliers_flag==1);
        inliers_X2 = X2(:, inliers_flag==1);
        best_X1 = X1(:,subset); % the X1 keypoints that matches best
        best_X2 = X2(:,subset); % the X2 keypoints that matches best
        best_H12 = H12;         % the transformation between best X1 and X2
    end
end


%% display

x1 = inliers_X1(1,:);
x2 = inliers_X2(1,:) + size(img1,2);
y1 = inliers_X1(2,:);
y2 = inliers_X2(2,:);

figure(3)
clf
imagesc(cat(2, img1, img2))
hold on
h = line([x1; x2], [y1; y2]);
set(h,'linewidth', 1)
axis image off
title('Best Matched Keypoints with RANSAC')


%% stitching - transform img1 & stitch to img2

x1 = inliers_X1(1,:);
y1 = inliers_X1(2,:);
x2 = inliers_X2(1,:);
y2 = inliers_X2(2,:);
    
% calculate H12 in [x2,y2,1] = H12 * [x1,y1,1]
% construct matrix A in Ah = 0
A = [];
for i = 1:inliers_max
    a = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
         0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i)];
    A = cat(1, A, a);
end

% compute SVD over A & form H
[U,S,V] = svd(A); % A = U*S*V'
h = V(:,end);
H12 = reshape(h,[3,3])';

% check the lower/upper bound of transformed pixel coordinates
vertex = [1, 1, 1; 1, h1, 1; w1, 1, 1; w1, h1, 1]';
pos = H12 * vertex; % position of transformed vertices
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

% take img2 into consideration
if col_min > 1
    col_min = 1;
end
if row_min > 1
    row_min = 1;
end

% deploy canvas
canvas1 = zeros(row_max-row_min+1, col_max-col_min+1, depth1);

% pixel-wise copy on img2
for r = 1:h2
    for c = 1:w2
        col = c-col_min+1;
        row = r-row_min+1;
        canvas1(row,col,:) = img2(r,c,:);
    end
end

% pixel-wise transformation on img1
for r = 1:h1
    for c = 1:w1
        pos = H12 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas1(row,col,:) = img1(r,c,:);
    end
end

figure(4)
imshow(uint8(canvas1))
title('Transform Image 1 & Stitch to Image 2')

%% stitching - transform img2 & stitch to img1

H21 = pinv(H12);

% check the lower/upper bound of transformed pixel coordinates
vertex = [1, 1, 1; 1, h2, 1; w2, 1, 1; w2, h2, 1]';
pos = H21 * vertex; % position of transformed vertices
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

% take img1 into consideration
if col_min > 1
    col_min = 1;
end
if row_min > 1
    row_min = 1;
end

% deploy canvas
canvas2 = zeros(row_max-row_min+1, col_max-col_min+1, depth2);

% pixel-wise copy on img1
for r = 1:h1
    for c = 1:w1
        col = c-col_min+1;
        row = r-row_min+1;
        canvas2(row,col,:) = img1(r,c,:);
    end
end

% pixel-wise transformation on img2
for r = 1:h2
    for c = 1:w2
        pos = H21 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas2(row,col,:) = img2(r,c,:);
    end
end

figure(5)
imshow(uint8(canvas2))
title('Transform Image 2 & Stitch to Image 1')


%% stitching - transform INTERPOLATED img1 & stitch to img2

[h1,w1,depth1] = size(img1);
[h2,w2,depth2] = size(img2);
x1 = inliers_X1(1,:);
y1 = inliers_X1(2,:);
x2 = inliers_X2(1,:);
y2 = inliers_X2(2,:);

scaling = 4;
img1_interpolated = imresize(img1, scaling, 'bicubic');
x1 = scaling * x1;
y1 = scaling * y1;
h1 = scaling * h1;
w1 = scaling * w1;

% calculate H12 in [x2,y2,1] = H12 * [x1,y1,1]
% construct matrix A in Ah = 0
A = [];
for i = 1:inliers_max
    a = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
         0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i)];
    A = cat(1, A, a);
end

% compute SVD over A & form H
[U,S,V] = svd(A); % A = U*S*V'
h = V(:,end);
H12 = reshape(h,[3,3])';

% check the lower/upper bound of transformed pixel coordinates
vertex = [1, 1, 1; 1, h1, 1; w1, 1, 1; w1, h1, 1]';
pos = H12 * vertex; % position of transformed vertices
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

% take img2 into consideration
if col_min > 1
    col_min = 1;
end
if row_min > 1
    row_min = 1;
end

% deploy canvas
canvas1_interpolated = zeros(row_max-row_min+1, col_max-col_min+1, depth1);

% pixel-wise copy on img2
for r = 1:h2
    for c = 1:w2
        col = c-col_min+1;
        row = r-row_min+1;
        canvas1_interpolated(row,col,:) = img2(r,c,:);
    end
end

% pixel-wise transformation on img1
for r = 1:h1
    for c = 1:w1
        pos = H12 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas1_interpolated(row,col,:) = img1_interpolated(r,c,:);
    end
end

figure(6)
imshow(uint8(canvas1_interpolated))
title('Transform Interpolated Image 1 & Stitch to Image 2')


%% stitching - transform INTERPOLATED img2 & stitch to img1

[h1,w1,depth1] = size(img1);
[h2,w2,depth2] = size(img2);
x1 = inliers_X1(1,:);
y1 = inliers_X1(2,:);
x2 = inliers_X2(1,:);
y2 = inliers_X2(2,:);

scaling = 4;
img2_interpolated = imresize(img2, scaling, 'bicubic');
x2 = scaling * x2;
y2 = scaling * y2;
h2 = scaling * h2;
w2 = scaling * w2;

% calculate H12 in [x2,y2,1] = H12 * [x1,y1,1]
% construct matrix A in Ah = 0
A = [];
for i = 1:inliers_max
    a = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
         0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i)];
    A = cat(1, A, a);
end

% compute SVD over A & form H
[U,S,V] = svd(A); % A = U*S*V'
h = V(:,end);
H12 = reshape(h,[3,3])';

% H21 = H12^(-1)
H21 = pinv(H12);

% check the lower/upper bound of transformed pixel coordinates
vertex = [1, 1, 1; 1, h2, 1; w2, 1, 1; w2, h2, 1]';
pos = H21 * vertex; % position of transformed vertices
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

% take img1 into consideration
if col_min > 1
    col_min = 1;
end
if row_min > 1
    row_min = 1;
end

% deploy canvas
canvas2_interpolated = zeros(row_max-row_min+1, col_max-col_min+1, depth2);

% pixel-wise copy on img1
for r = 1:h1
    for c = 1:w1
        col = c-col_min+1;
        row = r-row_min+1;
        canvas2_interpolated(row,col,:) = img1(r,c,:);
    end
end

% pixel-wise transformation on img2
for r = 1:h2
    for c = 1:w2
        pos = H21 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas2_interpolated(row,col,:) = img2_interpolated(r,c,:);
    end
end

figure(7)
imshow(uint8(canvas2_interpolated))
title('Transform Interpolated Image 2 & Stitch to Image 1')