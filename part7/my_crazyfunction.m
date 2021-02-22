function canvas = my_crazyfunction(canvas, img, T, node, father, H, H_this)

fprintf(['Calculating H' num2str(node) num2str(father) '... '])
% update homography matrix
H_this = H_this * H(node, father).h;
fprintf('Done.\n')

fprintf('Deploying canvas... ')
% save last canvas
canvas_temp = canvas.img;
% check the size of new canvas
h = img(node).h;
w = img(node).w;

vertex = [1, 1, 1;      % top-left
          1, h, 1;      % bottom-left
          w, 1, 1;      % top-right
          w, h, 1]';    % bottom-right

pos = H_this * vertex;
col = round(pos(1,:)./pos(3,:)) + canvas.pos(2);
row = round(pos(2,:)./pos(3,:)) + canvas.pos(1);
col_min = min(col); col_max = max(col);
row_min = min(row); row_max = max(row);

col_min = min(col_min, 1); col_max = max(col_max, size(canvas_temp, 2));
row_min = min(row_min, 1); row_max = max(row_max, size(canvas_temp, 1));

% deploy canvas
canvas.img = zeros(row_max-row_min+1, col_max-col_min+1, size(canvas_temp, 3));
fprintf('Done.\n')

% pixel-wise copy on last canvas (canvas_temp)
fprintf('Copying canvas... ')
for r = 1:size(canvas_temp, 1)
    for c = 1:size(canvas_temp, 2)
        col = c-col_min+1;
        row = r-row_min+1;
        canvas.img(row,col,:) = canvas_temp(r,c,:);
    end
end
fprintf('Done.\n')

% pixel-wise transformation on img1
fprintf(['Transfroming img' num2str(node) '... '])
for r = 1:img(node).h
    for c = 1:img(node).w
        pos = H_this * [c;r;1];
        col = round(pos(1)/pos(3))-col_min+1 + canvas.pos(2);
        row = round(pos(2)/pos(3))-row_min+1 + canvas.pos(1);
        canvas.img(row,col,:) = img(node).img(r,c,:);
    end
end

canvas.pos(1) = canvas.pos(1)-row_min+1;
canvas.pos(2) = canvas.pos(2)-col_min+1;
fprintf('Done.\n')

figure
imshow(uint8(canvas.img))
title(['Transform Image ' num2str(node)])


n = neighbors(T,node);
n(n==father) = [];

if isempty(n)
    return
end

for i = n
    canvas = my_crazyfunction(canvas, img, T, i, node, H, H_this);
end
    
