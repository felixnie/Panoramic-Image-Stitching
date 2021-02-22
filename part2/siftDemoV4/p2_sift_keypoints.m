% Part 2: SIFT Features and Descriptors - siftDemoV4
%
% In this part, I used SIFT functions from both siftDemoV4 and VLFeat to
% generate the keypoints and descriptors, then show them with the original
% image. siftDemoV4 provides function SIFT and SHOWKEYS.
%
% SIFT extracts the keypoint info, including keypoint location (x, y),
% scale and orientation, as well as the descriptors. Then we show the
% descriptors as arrows, indicating the location, scale and orientation of
% the keypoints.
%
% This process is primitive and time consuming. For better visualization of
% descriptors, please run P2_SIFT_DESCRIPTORS.
%

clear all
close all

% please change rootpath to the project root path
rootpath = 'C:\Users\nieht\EE5371 CA1';

% add path so that sift can find the images
addpath(rootpath)

% call sift.m to extract the keypoints and descriptors
[image, descriptors, locs] = sift('im02.jpg');

% show the keypoints as vectors
showkeys(image, locs)
