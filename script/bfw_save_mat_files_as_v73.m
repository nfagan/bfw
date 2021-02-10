source_directory = '';
output_directory = '';

allow_overwrite = false;

mat_files = shared_utils.io.findmat( source_directory );

for i = 1:numel(mat_files)    
  filename = shared_utils.io.filenames( mat_files{i}, true );    
  fprintf( '\n Processing "%s" (%d of %d)', filename, i, numel(mat_files) );
  
  dest_file_path = fullfile( output_directory, filename );
  can_save = ~shared_utils.io.fexists( dest_file_path ) || allow_overwrite;
  
  if ( can_save )
    file_contents = load( mat_files{i} );
    save( dest_file_path, '-v7.3', '-struct', 'file_contents' );
  else
    fprintf( '\n Skipping "%s" because it already exists.', filename );
  end
end