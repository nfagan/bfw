function to_keep = mask_significant_unit_info(labels, unit_info, mask, find_func)

if ( nargin < 3 )
  mask = rowmask( labels );
end

if ( nargin < 4 )
  find_func = @find;
end

uuids = cellfun( @(x) sprintf('unit_uuid__%d', x), {unit_info.unit}, 'un', 0 );
regions = [ unit_info.region ];
sessions = [ unit_info.session ];
regions(strcmp(regions, 'accg')) = { 'acc' };

id_set = [ uuids(:), regions(:), sessions(:) ];

if ( isequal(find_func, @find) )
  to_keep = cell( rows(id_set), 1 );
  
  for i = 1:rows(id_set)
    to_keep{i} = find_func( labels, id_set(i, :), mask );
  end
  
  to_keep = unique( vertcat(to_keep{:}) );
  
elseif ( isequal(find_func, @findnot) )
  to_keep = mask;

  for i = 1:rows(id_set)
    to_keep = find_func( labels, id_set(i, :), to_keep );
  end
else
  error( 'Unrecognized find function "%s".', func2str(find_func) );
end

end