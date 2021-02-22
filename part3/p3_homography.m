% Part 3: Homography
%
% In this part, the script contains 6 main stages shown as follow:
%
% 1. Manual selection of the keypoints
% 	 You can select the keypoints with cursor by single-clicking on the
%    image and end with a double-click. For example, if you want to select
%    4 points, click 3 times and double-click on your 4th point.
%    You can select more than 4 pairs of points, but please make sure the
%    order you click in both images are the same.
%
% 2. Compute H12 in [x2,y2,1] = H12 * [x1,y1,1]
%    First I construct matrix A in Ah = 0, then compute SVD over A to form
%    H12.
%
% 3. Transform the image 1 to match image 2
%    First I deploy the canvas and make sure the transformed coordinates
%    will not fall outside the canvas by firstly transform the vertices of
%    the image and set the size. Then I run the pixel-wise transformation.
%
% 4. H21 in [x1,y1,1] = H21 * [x2,y2,1]
%    Here a easy way to get H21 is calculate the inverse matrix of H12.
%
% 5. Transform the image 2 to match image 1
%    Same as step 3.
%
% 6. Avoid image tearing
%    There are some ways to prevent small images from being tore up when
%    transforming to large scale. One is interpolation, which will be used
%    in the next part. Here I used a cheap method called 2D order-statistic
%    filtering, which is just copying the maximum from the pixels around
%    the gaps. This works pretty good for simple images like this.
%

clear all
close all

% load images
img1 = imread('h1.jpg');
img2 = imread('h2.jpg');

% manually select the keypoints
figure
imshow(img1)
[x1,y1] = getpts;
[h1,w1,d1] = size(img1);
figure
imshow(img2)
[x2,y2] = getpts;
[h2,w2,d2] = size(img2);

len = length(x1);

%% compute H12 in [x2,y2,1] = H12 * [x1,y1,1]

% construct matrix A in Ah = 0
A = zeros(len*2,9);
for i = 1:len
    A([i,i+len],:) = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
                      0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i)];
end

% compute SVD over A & form H
[U,S,V] = svd(A); % A = U*S*V'
h = V(:,end);
H12 = reshape(h,[3,3])';

%% display

% check the lower/upper bound of transformed pixel coordinates
vertex = [1, 1, 1; 1, h1, 1; w1, 1, 1; w1, h1, 1]';
pos = H12 * vertex; % position of transformed vertices
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

% deploy canvas
canvas1 = zeros(row_max-row_min+1, col_max-col_min+1, d1);

% pixel-wise transformation
for r = 1:h1
    for c = 1:w1
        pos = H12 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas1(row,col,:) = img1(r,c,:);
    end
end

figure
imshow(uint8(canvas1))

%% H21 in [x1,y1,1] = H21 * [x2,y2,1]

H21 = pinv(H12);

%% display

% check the lower/upper bound of transformed pixel coordinates
vertex = [1, 1, 1; 1, h2, 1; w2, 1, 1; w2, h2, 1]';
pos = H21 * vertex; % position of transformed vertices
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

% deploy canvas
canvas2 = zeros(row_max-row_min+1, col_max-col_min+1, d2);

% pixel-wise transformation
for r = 1:h2
    for c = 1:w2
        pos = H21 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas2(row,col,:) = img2(r,c,:);
    end
end

figure
imshow(uint8(canvas2))

%% 2-D order-statistic filtering

canvas2_enhanced = zeros(size(canvas2));
for i = 1:d2
    canvas2_enhanced(:,:,i) = ordfilt2(canvas2(:,:,i),25,true(5));
end
figure
imshow(uint8(canvas2_enhanced))
