function [dat, labs] = find_labeled_starts(vec, labs)

assert_ispair( vec, labs );
assert( rows(labs) == 1, 'Specify data as a row vector.' );

[starts, durs] = shared_utils.logical.find_all_starts( vec );

repmat( labs, numel(starts) );
dat = [ starts(:), durs(:) ];

end