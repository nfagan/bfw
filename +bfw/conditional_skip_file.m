function should_skip = conditional_skip_file( file, allow_overwrite )

should_skip = false;

if ( ~allow_overwrite && shared_utils.io.fexists(file) )
  fprintf( '\n Skipping "%s" because it already exists.', file );
  should_skip = true;
end

end