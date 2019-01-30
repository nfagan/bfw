function validatefiles(files, required_files)

if ( ~shared_utils.general.is_map_like(files) )
  error( ['Expected files aggregate to be a struct, containers.Map,' ...
    , ' or Matlab object; was "%s".'], class(files) );
end

required_files = cellstr( required_files );
is_key = shared_utils.general.is_key( files, required_files );

if ( ~all(is_key) )
  missing_keys = required_files( ~is_key );
  missing_key_str = get_error_str_missing_files( missing_keys );
  
  error( missing_key_str );
end

end

function str = get_error_str_missing_files(required_files)

base_text = 'The files aggregate is missing these required entries: ';
str = sprintf( '\n\n - %s', strjoin(sort(required_files), '\n - ') );
str = sprintf( '%s%s', base_text, str );

end