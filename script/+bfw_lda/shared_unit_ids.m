function [ids, cats] = shared_unit_ids(a, b, mask_a, mask_b)

if ( nargin < 3 )
  mask_a = rowmask( a );
end
if ( nargin < 4 )
  mask_b = rowmask( b );
end

cats = { 'unit_uuid', 'channel', 'region', 'session' };
get_cell_ids = @(x, m) combs(x, cats, m);
join_cell_ids = @(x) fcat.strjoin(x, '');

ids_a = get_cell_ids( a, mask_a );
ids_b = get_cell_ids( b, mask_b );

joined_a = join_cell_ids( ids_a );
joined_b = join_cell_ids( ids_b );

[~, shared_ind] = intersect( joined_a, joined_b );
ids = ids_a(:, shared_ind);

end