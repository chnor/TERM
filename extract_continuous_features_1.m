
function extract_continuous_features_1(filename_in, filename_out)
    
    r = load(filename_in);
    load counts;
    p = bsxfun(@rdivide, r, counts');
    [mu, sigma, gamma] = pdf_skewness(p, 1:209);
    res = [mu, sigma, gamma];
    dlmwrite(filename_out, res, 'delimiter', ' ');
    
end