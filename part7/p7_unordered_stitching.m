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
num_img = 4;

for i = 1:num_img
    fprintf(['Loading image ' num2str(i) '/' num2str(num_img) '... '])
    img(i).img                      = imread(['utown' num2str(i) '.jpg']);
   [img(i).h, img(i).w, ~]          = size(img(i).img);
   [img(i).f, img(i).d]             = vl_sift(im2single(rgb2gray(img(i).img)));
    img(i).d                        = double(img(i).d);
    fprintf('Done.\n')
end


G = graph;
for i = 1 : num_img - 1
    for j = i + 1 : num_img
        % find matching descriptors
        fprintf(['Checking image ' num2str(i) ' & ' num2str(j) '... '])
        [matches(i,j).matches, matches(i,j).scores] = ...
            my_match(img(i).img,    img(j).img, ...
                     img(i).f,      img(j).f, ...
                     img(i).d,      img(j).d, ...
                     'none',        1.5);
        % find inliers
        [inliers(i,j).num, inliers(i,j).X1, inliers(i,j).X2, ~, ~, ~] = ...
            my_ransac(img(i).img,   img(j).img, ...
                      img(i).f,     img(j).f, ...
                      'none',       matches(i,j).matches, 5, 200, 6^2);
        % homography
        H(i,j).h = my_homography(   inliers(i,j).X1(1,:), ...
                                    inliers(i,j).X1(2,:), ...
                                    inliers(i,j).X2(1,:), ...
                                    inliers(i,j).X2(2,:), ...
                                    inliers(i,j).num);
        H(j,i).h = pinv(H(i,j).h);
        % transform j to i and count descriptors inside overlapping area
        % coordinates of MATCHED descriptors (inliers + ouliers)
        J = img(j).f(1:2,matches(i,j).matches(2,:));
        J(3,:) = 1;                     % turn into homography coordinates
        J_transformed = H(j,i).h * J;	% transform from j to i
        J_transformed = J_transformed./J_transformed(3,:);
        % check if the transformed features lie inside the overlapped area
        num_overlap = sum(J_transformed(1,:) > 0 & J_transformed(1,:) <= img(i).w & ...
                          J_transformed(2,:) > 0 & J_transformed(2,:) <= img(i).h);
        alpha = 8;
        beta = 0.3;
        weight = inliers(i,j).num / (alpha + beta * num_overlap);
        format short
        fprintf(['w ' num2str(weight) ' \tn ' num2str(inliers(i,j).num) ' \tN ' num2str(num_overlap)])
        if inliers(i,j).num > alpha + beta * num_overlap
            G = addedge(G, i, j, weight);
            fprintf('\tMatched.\n')
        else
            fprintf('\tDenied.\n')
        end
    end
end

figure
G.Edges.Weight = -G.Edges.Weight;
[T,pred] = minspantree(G);
p = plot(G, 'EdgeLabel', G.Edges.Weight);
highlight(p,T)

figure
plot(T)

T.Edges.Weight = ones(length(T.Edges.Weight), 1);
d = distances(T);
[farthest, root] = min(max(d, [], 2));
fprintf(['The root is node ' num2str(root) '.\n' ...
         'The farthest distance from root is ' num2str(farthest) '.\n'])

canvas.img = img(root).img; % the image to display in canvas
canvas.pos = [0, 0];        % the position of root image (top-left)
n = neighbors(T, root);
for i = 1:length(n)
    canvas = my_crazyfunction(canvas, img, T, n(i), root, H, eye(3));
end

figure
imshow(uint8(canvas.img))
title(['Transform Images & Stitch to Image ' num2str(root)])