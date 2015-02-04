
function extract_mi_tf_idf(filename_in, filename_out_mi, filename_out_tf_idf)
    
    r = load(filename_in);
    prev_w  = r(:, 1); % Previous word
    w       = r(:, 2); % Current word
    bigram  = r(:, 3); % Current bigram
    file_no = r(:, 4); % File no
    
    word_transition = sparse(prev_w, w, 1);
    file_to_term    = sparse([file_no, file_no], [w, bigram], 1);
    
    mi     = preprocess_mi(word_transition);
    tf_idf = preprocess_tf_idf(file_to_term);
    
    [a, b, c] = find(mi);
    dlmwrite(filename_out_mi, [a, b, c], 'delimiter', ' ');
    
    [a, b, c] = find(tf_idf);
    dlmwrite(filename_out_tf_idf, [a, b, c], 'delimiter', ' ');
    
end