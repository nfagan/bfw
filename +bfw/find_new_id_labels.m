function [unit_I, match_rows, new_ids] = find_new_id_labels(spike_labels, id_matrix)

[unit_I, unit_C] = findall( spike_labels ...
  , {'unit_uuid', 'unit_index', 'channel', 'region', 'session'} );

unit_C(1, :) = strrep( unit_C(1, :), 'unit_uuid__', '' );
unit_C(2, :) = strrep( unit_C(2, :), 'unit_index__', '' );
unit_C(4, :) = strrep( unit_C(4, :), 'accg', 'acc' );

[~, orig_inds] = ismember( ...
    {'original_uuid', 'unit_index', 'channel', 'region', 'session'} ...
  , id_matrix.header );

[~, new_id_ind] = ismember( 'new_uuid', id_matrix.header );

matched = id_matrix.info(:, orig_inds);
matched_joined = fcat.strjoin( matched', ' ' )';
match_rows = zeros( numel(unit_I), 1 );
new_ids = cell( numel(match_rows), 1 );

for i = 1:numel(unit_I)
  search_unit_id = strjoin( unit_C(:, i) );
  match_ind = strcmp( matched_joined, search_unit_id );
  assert( nnz(match_ind) == 1 );
  match_rows(i) = find( match_ind );
  new_ids{i} = id_matrix.info{match_ind, new_id_ind};
end

end