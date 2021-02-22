% Part 4: Manual Homography + Sticthing
%
% The main steps are same from part 3. By manually selecting points in both
% images, they are stitched and displayed in the same canvas. This need 2
% steps: pixel-wise copy of the first image and pixel-wise transformation
% of the second one.
%
% Another difference from part 3 is, interpolation is used on the original
% image to avoid tearing up.
%
% Please change rootpath to the project root path so that we can find the
% images.
%

clear all
close all

% please change rootpath to the project root path
rootpath = 'C:\Users\nieht\EE5371 CA1';

% perform one-time setup of vlfeat
run([rootpath '\vlfeat-0.9.21\toolbox\vl_setup'])

img1 = imread('im01.jpg');
img2 = imread('im02.jpg');
figure
imshow(img1)
[x1,y1] = getpts;
[h1,w1,d1] = size(img1);
figure
imshow(img2)
[x2,y2] = getpts;
[h2,w2,d2] = size(img2);

len = length(x1);

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
canvas = zeros(row_max-row_min+1, col_max-col_min+1, d2);

% pixel-wise copy on img1
for r = 1:h1
    for c = 1:w1
        col = c-col_min+1;
        row = r-row_min+1;
        canvas(row,col,:) = img1(r,c,:);
    end
end

% pixel-wise transformation on img2
for r = 1:h2
    for c = 1:w2
        pos = H21 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas(row,col,:) = img2(r,c,:);
    end
end

figure
imshow(uint8(canvas))
title('Transform Image 2 & Stitch to Image 1')


%% interpolation on original image to aviod tearing

scaling = 4;
img2 = imresize(img2, scaling, 'bicubic');
x2 = scaling * x2;
y2 = scaling * y2;
h2 = scaling * h2;
w2 = scaling * w2;

A = zeros(len*2,9);
for i = 1:len
    A([i,i+len],:) = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
                      0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i)];
end

[U,S,V] = svd(A);
h = V(:,end);
H12 = reshape(h,[3,3])';
H21 = pinv(H12);

vertex = [1, 1, 1; 1, h2, 1; w2, 1, 1; w2, h2, 1]';
pos = H21 * vertex;
col = round(pos(1,:)./pos(3,:));
row = round(pos(2,:)./pos(3,:));
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

if col_min > 1
    col_min = 1;
end
if row_min > 1
    row_min = 1;
end

canvas = zeros(row_max-row_min+1, col_max-col_min+1, d2);

for r = 1:h1
    for c = 1:w1
        col = c-col_min+1;
        row = r-row_min+1;
        canvas(row,col,:) = img1(r,c,:);
    end
end

for r = 1:h2
    for c = 1:w2
        pos = H21 * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1;
        row = round(pos(2)/pos(3))-row_min+1;
        canvas(row,col,:) = img2(r,c,:);
    end
end

figure
imshow(uint8(canvas))
title('Transform Interpolated Image 2 & Stitch to Image 1')