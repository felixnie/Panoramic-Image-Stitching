function H12 = my_homography(x1, y1, x2, y2, len)

A = [];
for i = 1:len
    a = [x1(i), y1(i), 1, 0, 0, 0, -x2(i)*x1(i), -x2(i)*y1(i), -x2(i);
         0, 0, 0, x1(i), y1(i), 1, -y2(i)*x1(i), -y2(i)*y1(i), -y2(i)];
    A = cat(1, A, a);
end

% compute SVD over A & form H
[U,S,V] = svd(A); % A = U*S*V'
h = V(:,end);
H12 = reshape(h,[3,3])';