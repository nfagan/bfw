function to_keep = mask_significant_unit_info(labels, unit_info, mask, find_func)

if ( nargin < 3 )
  mask = rowmask( labels );
end

if ( nargin < 4 )
  find_func = @find;
end

if ( isfield(unit_info, 'unit') )
  uuids = extract_uuids( {unit_info.unit} );
else
  uuids = extract_uuids( {unit_info.uuid} );
end

regions = cellstr_extract( unit_info, 'region' );

if ( isfield(unit_info, 'session') )
  sessions = cellstr_extract( unit_info, 'session' );
else
  sessions = cellstr_extract( unit_info, 'date' );
end

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

function out = cellstr_extract(in, f)

out = cell( size(in) );

for i = 1:numel(in)
  v = in(i).(f);
  
  if ( iscell(v) )
    out(i) = v;
  else
    out{i} = v;
  end
end

end

function uuids = extract_uuids(unit_ids)

prefix = 'unit_uuid__';
uuids = cell( size(unit_ids) );

for i = 1:numel(unit_ids)
  if ( ischar(unit_ids{i}) )
    uuids{i} = sprintf( '%s%s', prefix, unit_ids{i} );
  else
    uuids{i} = sprintf( '%s%d', prefix, unit_ids{i} );
  end
end

end