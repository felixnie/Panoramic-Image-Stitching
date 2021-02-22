function img_norm = my_norm(img)

img_max = max(max(img));
img_min = min(min(img));
maximum = 255;
minimum = 0;
img_norm = (img-img_min) / (img_max-img_min) * ...
    (maximum-minimum) + minimum;
