function [inliers_max, inliers_X1, inliers_X2, best_X1, best_X2, best_H12] ...
         = my_ransac(img1, img2, f1, f2, display, matches, n, iter, epsilon)

X1 = f1(1:2,matches(1,:));
X1(3,:) = 1;
X2 = f2(1:2,matches(2,:));
X2(3,:) = 1;                    % keypoints in Homogeneous coordinate

num_matches = size(matches,2);  % number of matches
% n = 4;                          % randomly select n matches
% iter = 200;                     % number of iterations
% epsilon = 6^2;                  % ε
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
if strcmp(display, 'disp')
    x1 = inliers_X1(1,:);
    x2 = inliers_X2(1,:) + size(img1,2);
    y1 = inliers_X1(2,:);
    y2 = inliers_X2(2,:);

    figure
    imagesc(cat(2, img1, img2))
    hold on
    h = line([x1; x2], [y1; y2]);
    set(h,'linewidth', 1)
    axis image off
    title('Best Matched Keypoints with RANSAC')
end