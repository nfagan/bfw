function labels = add_n_back_labels(labels, n_back_strs, of, prefix)

of = shared_utils.cell.ensure_cell( of );
assert( numel(of) == size(n_back_strs, 2) ...
  , 'Expected %d columns of n_back_strs.', size(n_back_strs, 2) );

for i = 1:numel(of)
  tmp = n_back_strs(:, i);
  tmp(strcmp(tmp, '')) = {sprintf('%s%s_undefined', prefix, of{i})};
  new_cat = sprintf( '%s%s', prefix, of{i} );
  addsetcat( labels, new_cat, tmp );
end

end