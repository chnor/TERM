
function [mu, sigma, gamma, beta] = pdf_skewness(p, x)
    
    % Calculate mean x
    r = bsxfun(@times, x, p);
    mu = sum(r, 2) ./ sum(p, 2);
    
    % Calculate x normalized around mean
    x_n = bsxfun(@minus, x, mu);
    
    % Calculate standard deviation of x
    sigma = sqrt(sum(p .* (x_n.^2), 2) ./ sum(p, 2));
    
    % Calculate skewness of x
%     gamma = (sum(p .* (x_n.^3), 2) ./ sum(p, 2)) ./ (sum(p .* (x_n.^2), 2) ./ (sum(p, 2) - 1)).^(3/2);
    gamma = (sum(p .* (x_n.^3), 2) ./ sum(p, 2)) ./ (sum(p .* (x_n.^2), 2) ./ (sum(p, 2))).^(3/2);
    
    % Calculate kurtosis of x
    beta = (sum(p .* (x_n.^4), 2) ./ sum(p, 2)) ./ (sum(p .* (x_n.^2), 2) ./ sum(p, 2)).^2;
    
    
    % Wrong but works anyway...
    
    % Calculate standard deviation of x
%     sigma = sqrt(sum(x_n.^2, 2) / numel(x));
    % Calculate skewness of x
%     gamma = (sum(x_n.^3, 2) / numel(x)) ./ (sum(x_n.^2, 2) / (numel(x) - 1)).^(3/2);
    % Calculate kurtosis of x
%     beta = (sum(x_n.^4, 2) / numel(x)) ./ (sum(x_n.^2, 2) / numel(x)).^2;
    
end