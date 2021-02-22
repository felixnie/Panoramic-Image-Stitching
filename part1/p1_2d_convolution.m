%% Part 1: 2D Convolution
clear all
close all

%% load image
filename = 'lena.png';
img_original = imread(filename);
% convert rgb or gray image into grayscale
img_original = im2gray(img_original);
figure
imshow(img_original)                % show initial image
img = double(img_original);         % convert from uint8 to double
title('Original image')

%% define the kernels

% Sobel vertical & horizonal kernel
sobel_x = [-1 0 1; -2 0 2; -1 0 1];
sobel_y = sobel_x';

% Gaussian kernel
m = 3; n = 3; sigma = 5; % size of Gaussian kernel
[M, N] = meshgrid(-(m-1)/2:(m-1)/2, -(n-1)/2:(n-1)/2);
gaussian = exp(-(M.^2+N.^2) / (2*sigma^2));
gaussian = gaussian ./ sum(gaussian(:));

% Haar-like masks
% the sum of each mask matrix is set to zero
% you can set your scale and parameters
scale = 3;
% edge features
haar_1 = imresize([1; -1], scale, 'nearest');
haar_2 = imresize([1, -1], scale, 'nearest');
% line features
haar_3 = imresize([1, -2, 1], scale, 'nearest');
haar_4 = imresize([1; -2; 1], scale, 'nearest');
% four-rectangle features
haar_5 = imresize([1, -1; -1, 1], scale, 'nearest');

%% verify the correctness of our Gaussian kernel
% with MATLAB predefined 2-D filter function fspecial
g = fspecial('gaussian', [m n], sigma);
diff_gaussian = sum(sum(abs(gaussian-g)));

%% verify the correctness of my_conv2 function
a = rand(4,5);
b = rand(3,3);
c = conv2(a,b,'same');
d = my_conv2(a,b);
diff_conv = sum(sum(abs(c-d))); % usually diff_conv < 1e-15

%% convolution (call my_conv2 function)

% Sobel filtering
% convolution
img_Sobel_x = my_conv2(img, sobel_x);
img_Sobel_y = my_conv2(img, sobel_y);
% normalization (call my_norm function)
img_Sobel_x = my_norm(img_Sobel_x);
img_Sobel_y = my_norm(img_Sobel_y);
img_Sobel = sqrt(img_Sobel_x.^2 + img_Sobel_y.^2);
img_Sobel = my_norm(img_Sobel);
% display
figure
subplot(2,2,1); imshow(img_original);        title('Original image')
subplot(2,2,2); imshow(img_Sobel_x,[0,255]); title('Sobel vertical kernel')
subplot(2,2,3); imshow(img_Sobel_y,[0,255]); title('Sobel horizonal kernel')
subplot(2,2,4); imshow(img_Sobel,[0,255]);   title('Gradient magnitude')

% Gaussian filtering
img_Gaussian = my_conv2(img, gaussian);
img_Gaussian = my_norm(img_Gaussian);
figure
imshow(img_Gaussian,[0,255])
title(['Gaussian filtering m=' num2str(m) ' n=' num2str(n) ' σ=' num2str(sigma)])

% Haar-like masks
img_Haar_1 = my_conv2(img, haar_1);
img_Haar_2 = my_conv2(img, haar_2);
img_Haar_3 = my_conv2(img, haar_3);
img_Haar_4 = my_conv2(img, haar_4);
img_Haar_5 = my_conv2(img, haar_5);
img_Haar_1 = my_norm(img_Haar_1);
img_Haar_2 = my_norm(img_Haar_2);
img_Haar_3 = my_norm(img_Haar_3);
img_Haar_4 = my_norm(img_Haar_4);
img_Haar_5 = my_norm(img_Haar_5);
figure
subplot(2,3,1); imshow(img_Haar_1,[0,255]); title(['haar_1 scale=' num2str(scale)])
subplot(2,3,2); imshow(img_Haar_2,[0,255]); title(['haar_2 scale=' num2str(scale)])
subplot(2,3,4); imshow(img_Haar_3,[0,255]); title(['haar_3 scale=' num2str(scale)])
subplot(2,3,5); imshow(img_Haar_4,[0,255]);	title(['haar_4 scale=' num2str(scale)])
subplot(2,3,6); imshow(img_Haar_5,[0,255]);	title(['haar_5 scale=' num2str(scale)])
