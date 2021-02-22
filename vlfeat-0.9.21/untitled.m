% close all
clear all

% perform one-time setup of vlfeat
vlfeatroot = 'C:\Users\nieht\EE5371\vlfeat-0.9.21';
run([vlfeatroot '\toolbox\vl_setup'])

% % load image
% img1 = imread('im01.jpg');
% img2 = imread('im02.jpg');
% 
% % extract keypoints and descriptors
% [f1,d1] = vl_sift(im2single(rgb2gray(img1)));
% [f2,d2] = vl_sift(im2single(rgb2gray(img2)));

% load image
img1 = im2single(imread('im01.jpg'));
img2 = im2single(imread('im02.jpg'));

% extract keypoints and descriptors
[f1,d1] = vl_sift(rgb2gray(img1));
[f2,d2] = vl_sift(rgb2gray(img2));


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

%% ransac
X1 = f1(1:2,matches(1,:));
X1(3,:) = 1;
X2 = f2(1:2,matches(2,:));
X2(3,:) = 1;                    % keypoints in Homogeneous coordinate

num_matches = size(matches,2);  % number of matches
n = 4;                          % randomly select n matches
iter = 200;                     % number of iterations
epsilon = 6*6;                % ε
inliers = zeros(1,iter);        % number of inliers
inliers_max = 0;                % maximum of inliers

for t = 1:iter
    subset = randperm(num_matches, n);
    x1 = X1(1,subset);
    y1 = X1(2,subset);
    x2 = X2(1,subset);
    y2 = X2(2,subset);
    
    A = [] ;
    for i = subset
        A = cat(1, A, kron(X1(:,i)', vl_hat(X2(:,i)))) ;
    end
    [U,S,V] = svd(A) ;
    H12 = reshape(V(:,9),3,3) ;

    X2_transform = H12 * X1;
    dx = X2_transform(1,:)./X2_transform(3,:) - X2(1,:)./X2(3,:);
    dy = X2_transform(2,:)./X2_transform(3,:) - X2(2,:)./X2(3,:);
    inliers_flag = (dx.*dx + dy.*dy) < epsilon;
    inliers_num = sum(inliers_flag);
    if inliers_num > inliers_max
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
