
function S = extract_tree_node_labels(tree, leaves, MAX_LENGTH)
    
    n_i = leaves;
    
%     MAX_LENGTH = 100;
    
    l = MAX_LENGTH * ones(size(leaves));
    
    for i = 1:MAX_LENGTH
%         disp(['Iteration ', num2str(i), ' / ', num2str(MAX_LENGTH)]);
        parents_i = tree.Parent(n_i);
        l(l == MAX_LENGTH & parents_i == 0) = i;
        parents_i(parents_i == 0) = 1;
        [~, d_i] = max(bsxfun(@eq, tree.Children(parents_i, :), n_i), [], 2);
        n_i = parents_i;
    end
    
    s = zeros(numel(leaves), MAX_LENGTH + 1);
    offset = l * (numel(leaves)) + (1:numel(leaves))';
    
    n_i = leaves;
    
    for i = 1:MAX_LENGTH
%         disp(['Iteration ', num2str(i), ' / ', num2str(MAX_LENGTH)]);
        parents_i = tree.Parent(n_i);
        parents_i(parents_i == 0) = 1;
        [~, d_i] = max(bsxfun(@eq, tree.Children(parents_i, :), n_i), [], 2);
        n_i = parents_i;
%         indices = MAX_LENGTH - offset - i + 1
%         indices = offset + i - 1;
%         indices = (1:numel(leaves))' + numel(leaves) * min((MAX_LENGTH + offset - i), MAX_LENGTH);
%         indices = (1:numel(leaves))' + numel(leaves) .* min((offset + i), MAX_LENGTH);
%         indices = numel(leaves) .* ((1:MAX_LENGTH) - 1) + offset + i - 1;
        s(offset) = d_i;
        offset = max(offset - numel(leaves), (1:numel(leaves))');
    end
    
%     S = cell(size(leaves));
    
    % Optimize this!
%     for i = 1:numel(leaves)
%         arrayfun(@num2str, s(i, 1:l(i)-1))
%         S{i} = arrayfun(@num2str, fliplr(s(i, 1:l(i)-1)));
%         S{i} = arrayfun(@num2str, fliplr(s(i, 1:MAX_LENGTH)));
%     end
    
    % Extract each row
    S = num2cell(s(:, 2:MAX_LENGTH+1), 2);
    % Stringify each row
    S = cellfun(@(x) sprintf('%d', x), S, 'UniformOutput', false);
    
end