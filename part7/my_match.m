function [matches, scores] = my_match(img1, img2, f1, f2, d1, d2, ...
                                      display, threshold)

% exhaustive search on matched descriptors
matches = [];
scores = [];

for i = 1:size(d1,2)
    closest_dist = Inf;
    second_closest_dist = Inf;
    best_match = 0;
    for j = 1:size(d2,2)
        % squared Euclidean distance
        d = d1(:,i) - d2(:,j);
        squared_dist = sum(d.^2);
        if squared_dist < closest_dist
            second_closest_dist = closest_dist;
            closest_dist = squared_dist;
            best_match = j;
        elseif squared_dist < second_closest_dist
            second_closest_dist = squared_dist;
        end
    end
    if threshold * closest_dist < second_closest_dist && best_match ~= 0
        matches = [matches [i best_match]'];
        scores = [scores closest_dist];
    end
end

[drop, perm] = sort(scores, 'descend');
matches = matches(:, perm);
scores = scores(perm);

% display
if strcmp(display, 'disp')
    x1 = f1(1,matches(1,:));
    x2 = f2(1,matches(2,:)) + size(img1,2);
    y1 = f1(2,matches(1,:));
    y2 = f2(2,matches(2,:));

    figure
    imagesc(cat(2, img1, img2))
    hold on
    h = line([x1; x2], [y1; y2]);
    set(h,'linewidth', 1)
    axis image off
    title('Matched Keypoints')
end