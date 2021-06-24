function i = pair_combination_indices(n)

i = unique( sort(dsp3.ncombvec(n, n), 1)', 'rows' );
i(i(:, 1) == i(:, 2), :) = [];

end