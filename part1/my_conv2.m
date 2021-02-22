function img_conv = my_conv2(img, kernel)

% get the input dimension
[row, col] = size(img);
[row_k, col_k] = size(kernel);

% zero padding
padding = zeros(row+row_k, col+col_k);
img_location_x = floor(row_k/2)+1 : floor(row_k/2)+row;
img_location_y = floor(col_k/2)+1 : floor(col_k/2)+col;
padding(img_location_x, img_location_y) = img;

img_conv = zeros(row, col);

% convolution
for i = 1:row
    for j = 1:col
        for m = 1:row_k
            for n = 1:col_k
                img_conv(i,j) = img_conv(i,j) + sum(sum(...
                    padding(i+m-1, j+n-1) * kernel(row_k-m+1, col_k-n+1)));
            end
        end
    end
end

