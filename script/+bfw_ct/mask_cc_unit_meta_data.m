function to_keep = mask_cc_unit_meta_data(labels, meta_data, mask)

if ( nargin < 3 )
  mask = rowmask( labels );
end

uuids = cellfun( @(x) sprintf('unit_uuid__%d', x), {meta_data.uuid}, 'un', 0 );
regions = { meta_data.region };
sessions = { meta_data.date };
regions(strcmp(regions, 'accg')) = { 'acc' };

id_set = [ uuids(:), regions(:), sessions(:) ];

to_keep = cell( rows(id_set), 1 );

for i = 1:rows(id_set)
  to_keep{i} = find( labels, id_set(i, :), mask );
end

to_keep = unique( vertcat(to_keep{:}) );

end