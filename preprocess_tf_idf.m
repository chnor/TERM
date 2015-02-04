
% Input: possibly sparse matrix containing each term frequency
%        where each row denotes a document, and each column a term

function tf_idf = preprocess_tf_idf(tf)
    
    disp('Calculating idf...');
    den = sum(tf ~= 0, 1); % Number of documents containing term i
    N = size(tf, 1); % Total number of documents
    idf = log(N ./ den)';
    disp('Done.');
    
    disp('Calculating tf-idf...');
    if issparse(tf)
        tf_idf = tf * spdiags(idf, 0, numel(idf), numel(idf));
    else
        tf_idf = bsxfun(@times, tf, idf');
    end
    tf_idf(isnan(tf_idf)) = 0;
    disp('Done.');
    
end