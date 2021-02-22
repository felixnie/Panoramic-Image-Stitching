% Part 2: SIFT Features and Descriptors - VLFeat
%
% In this script, function VL_SIFT from VLFeat libraries is used to
% generate descriptors, while VL_PLOTFRAME and VL_PLOTSIFTDESCRIPTOR is
% used to show the keypoints and descriptors. We can change the number of
% descriptors to display by setting N.
%
% Please change rootpath to the project root path so that we can setup
% VLFeat librabies.
%

clear all
close all

% please change rootpath to the project root path
rootpath = 'C:\Users\nieht\EE5371 CA1';

% perform one-time setup of vlfeat
run([rootpath '\vlfeat-0.9.21\toolbox\vl_setup'])

% fix the seed to generate repeatable results
randn('state',0) ;
rand('state',0) ;

% load image
filepath = [rootpath '\' 'im02.jpg'];
img = imread(filepath);

figure(1)
clf
image(img)
colormap gray
axis equal
axis off
axis tight
hold on

% convert the to required format
img = single(rgb2gray(img)) ;

% run SIFT
[f,d] = vl_sift(img) ;

% randomly select n keypoints for descriptor visualization
n = 50;
perm = randperm(size(f,2)) ;
sel  = perm(1:n) ;
h1   = vl_plotframe(f(:,sel)) ; set(h1,'color','k','linewidth',3) ;
h2   = vl_plotframe(f(:,sel)) ; set(h2,'color','y','linewidth',2) ;

h3 = vl_plotsiftdescriptor(d(:,sel),f(:,sel)) ;
set(h3,'color','k','linewidth',2) ;
h4 = vl_plotsiftdescriptor(d(:,sel),f(:,sel)) ;
set(h4,'color','g','linewidth',1) ;
h1   = vl_plotframe(f(:,sel)) ; set(h1,'color','k','linewidth',3) ;
h2   = vl_plotframe(f(:,sel)) ; set(h2,'color','y','linewidth',2) ;
