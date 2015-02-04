
% Input: possibly sparse matrix containing each frequencies
%        of cooccurence of two variables

function mi = preprocess_mi(f_x1_y1)
    
    % Note: if v is any vector, then v(:) makes it a column vector
    
    [m, n] = size(f_x1_y1);
    
    f_x1 = sum(f_x1_y1, 2);
    f_y1 = sum(f_x1_y1, 1);
    f   = sum(f_x1);
    f_x0 = f - f_x1;
    f_y0 = f - f_y1;
    
%     f_x0_y1 = bsxfun(@minus, f_x, f_x_y);
    f_x1_mat = spdiags(f_x1(:), 0, numel(f_x1), numel(f_x1)) * (f_x1_y1 ~= 0);
    f_x0_mat = spdiags(f_x0(:), 0, numel(f_x0), numel(f_x0)) * (f_x1_y1 ~= 0);
    f_x1_y0 = f_x1_mat - f_x1_y1;
    
%     f_x1_y0 = bsxfun(@minus, f_y, f_x_y);
    f_y1_mat = (f_x1_y1 ~= 0) * spdiags(f_y1(:), 0, numel(f_y1), numel(f_y1));
    f_y0_mat = (f_x1_y1 ~= 0) * spdiags(f_y0(:), 0, numel(f_y0), numel(f_y0));
    f_x0_y1 = f_y1_mat - f_x1_y1;
    
    f_x0_y0 = f * (f_x1_y1 ~= 0) - f_x1_y1 - f_x1_y0 - f_x0_y1;
    
    f_mat = f * (f_x1_y1 ~= 0);
    
    mi = sparse(m, n);
    
    ent = @(f_x_y, f_x, f_y) (f_x_y ./ f) .* (spfun(@log2, f_mat) + spfun(@log2, f_x_y) - spfun(@log2, f_x) - spfun(@log2, f_y));
    
    mi = mi + ent(f_x0_y0, f_x0_mat, f_y0_mat);
    mi = mi + ent(f_x0_y1, f_x0_mat, f_y1_mat);
    mi = mi + ent(f_x1_y0, f_x1_mat, f_y0_mat);
    mi = mi + ent(f_x1_y1, f_x1_mat, f_y1_mat);
    
%     mi = mi + (f_x1_y1 ./ f) .* (spfun(@log2, f_mat) + spfun(@log2, f_x1_y1) - spfun(@log2, f_x_mat) - spfun(@log2, f_y_mat))
    
    return;
    
    p_y = f_x1_y1 * spdiags(1 ./ f_y', 0, n, n);
    p_x = spdiags(1 ./ f_x, 0, m, m) * f_x1_y1;
    
%     p_x = spdiags(f_x(:) / sum(f_x), 0, numel(f_x), numel(f_x)) * (f_x1_y1 ~= 0);
%     p_y = (f_x1_y1 ~= 0) * spdiags(f_y(:) / sum(f_y), 0, numel(f_y), numel(f_y));
    
    % p(x, y)
    p_x0_y0 = f_x0_y0 ./ f;
    p_x0_y1 = f_x0_y1 ./ f;
    p_x1_y0 = f_x1_y0 ./ f;
    p_x1_y1 = f_x1_y1 ./ f;
    
%     ent = @(p) - p .* spfun(@log, p) - spfun(@(x)(1-x), p) .* spfun(@(x) log(1-x), p);
    
    % Joint entropy H(X, Y)
    H = sparse(m, n);
    H = H - p_x0_y0 .* spfun(@log, p_x0_y0);
    H = H - p_x0_y1 .* spfun(@log, p_x0_y1);
    H = H - p_x1_y0 .* spfun(@log, p_x1_y0);
    H = H - p_x1_y1 .* spfun(@log, p_x1_y1);
    
    ent_x = spfun(@(x) 1-x, p_x);
%     ent_x = p_x;
    ent_x = - ent_x .* spfun(@log, ent_x);
    ent_x = ent_x - p_x .* spfun(@log, p_x);
    
    ent_y = spfun(@(x) 1-x, p_y);
%     ent_y = p_y;
    ent_y = - ent_y .* spfun(@log, ent_y);
    ent_y = ent_y - p_y .* spfun(@log, p_y);
    
%     nnz(p_x) ./ numel(p_x)
    mi = -H;
    mi = mi + ent_x;
    mi = mi + ent_y;
    
%     mi = p_x_y .* ( log2(p_x_y) - log2(p_x) - log2(p_y) );
    
end

% function x = ent(p)
%     
%     x = p .* spfun(@log, p);
%     
% end