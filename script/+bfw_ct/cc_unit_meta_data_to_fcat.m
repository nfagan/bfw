function out = cc_unit_meta_data_to_fcat(meta_data)

if ( isfield(meta_data, 'uuid') )
  uuid_fieldname = 'uuid';
else
  uuid_fieldname = 'unit';
end

if ( isfield(meta_data, 'date') )
  session_fieldname = 'date';
else
  session_fieldname = 'session';
end

uuids = uuids_to_string( {meta_data.(uuid_fieldname)} );

regions = cellstr_extract( meta_data, 'region' );
sessions = cellstr_extract( meta_data, session_fieldname );
regions(strcmp(regions, 'accg')) = { 'acc' };

out = fcat.create( 'unit_uuid', uuids, 'session', sessions, 'region', regions );

end

function out = uuids_to_string(uuids)

out = cell( size(uuids) );
pattern = 'unit_uuid__';

for i = 1:numel(out)
  if ( ischar(uuids{i}) )
    out{i} = sprintf( '%s%s', pattern, uuids{i} );
  elseif ( isa(uuids{i}, 'double') )
    out{i} = sprintf( '%s%d', pattern, uuids{i} );
  else
    error( 'Unrecognized uuid class "%s".', class(uuids{i}) );
  end
end

end

function out = cellstr_extract(meta_data, fieldname)

if ( numel(meta_data) == 0 )
  out = {};
  return
end

if ( iscell(meta_data(1).(fieldname)) )
  out = [ meta_data.(fieldname) ];
else
  out = { meta_data.(fieldname) };
end

end