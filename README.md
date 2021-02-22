# Assignment 1: Panoramic Image Stitching

Date: Oct 9, 2020

Link: [https://felixnie.github.io/modules/2020-12-04-ee5731-2-panoramic-image-stitching/](https://felixnie.github.io/modules/2020-12-04-ee5731-2-panoramic-image-stitching/)

## Files in Root Directory

Some files and libraries are used in multiple parts. Sharing them can make the project more compact. But this needs you to setup the root path of the project by setting the **rootpath** variable in some of the scripts. Please read the instructions in the front of each script, or call 'help *filename*' in MATLAB.

- *.jpg - Input images
- vlfeat-0.9.21 - VLFeat libraries, for running SIFT algorithm

## Part 1: 2D Convolution

- part1.m - Main file
- my_conv2.m - Function for 2D convolution
- my_norm.m - Function for image normalization

## Part 2: SIFT Features and Descriptors

There are 2 subdirectories for this part, each contains a main .m file.

One is based on [siftDemoV4](https://www.cs.ubc.ca/~lowe/keypoints/) (SIFT demo program, Version 4, July 2005), an implementation of SIFT keypoint detector, created by David Lowe.

Another great implementation is [VLFeat](https://www.vlfeat.org/overview/sift.html) created by Andrea Vedaldi.

For more information, please run:
```
help p2_sift_keypoints
help p2_sift_descriptors
```

- siftDemoV4
  - p2_sift_keypoints.m - Main file
  - File from siftDemoV4 (Only relevant files are shown)
    - sift.m - Function to extract keypoints and descriptors
    - showkeys.m - Show the keyboints as vectors

- vlfeat
  - p2_sift_descriptors.m - Main file

## Part 3: Homography

- p3_homography.m - Main file
- *.jpg/png - Input images

For more information, run:
```
help p3_homography
```

## Part 4: Manual Homography + Sticthing

- p4_homography_sticthing.m - Main file

For more information, run:
```
help p4_homography_sticthing
```

## Part 5: Homography + RANSAC

- p5_homography_ransac.m - Main file
 
For more information, run:
```
help p5_homography_ransac
```

## Part 6: Basic Panoramic Image

- p6_homography_ransac_multi_image.m - Main file
- my_match.m - Function to match the descriptors using squared Euclidean distance
- my_ransac.m - RANSAC algorithm
- my_homography.m - Function to compute homography matrix
- result.fig - Output

For more information, run:
```
help p6_homography_ransac_multi_image
```

## Part 7: Advanced Panoramic Image

- p7_unordered_stitching.m - Main file
- my_match.m - Function to match the descriptors using squared Euclidean distance
- my_ransac.m - RANSAC algorithm
- my_homography.m - Function to compute homography matrix
- my_crazyfunction.m - Function to recursively compute H and do the transformation
