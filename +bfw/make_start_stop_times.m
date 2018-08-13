function make_start_stop_times(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

sync_p = bfw.get_intermediate_directory( 'sync' );
output_p = bfw.get_intermediate_directory( 'start_stop' );

sync_mats = bfw.require_intermediate_mats( params.files, sync_p, params.files_containing );

for i = 1:numel(sync_mats)
  fprintf( '\n %d of %d', i, numel(sync_mats) );
  
  sync_file = shared_utils.io.fload( sync_mats{i} );
  
  un_filename = sync_file.unified_filename;
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  mat_col = strcmp( sync_file.sync_key, 'mat' );
  plex_col = strcmp( sync_file.sync_key, 'plex' );
  
  fv_mat_start = sync_file.plex_sync(1, mat_col);
  fv_plex_start = sync_file.plex_sync(1, plex_col);
  fv_mat_stop = sync_file.plex_sync(end, mat_col);
  fv_plex_stop = sync_file.plex_sync(end, plex_col);
  
  start_stop_struct = struct();
  start_stop_struct.fv_mat_start = fv_mat_start;
  start_stop_struct.fv_mat_stop = fv_mat_stop;
  start_stop_struct.fv_plex_start = fv_plex_start;
  start_stop_struct.fv_plex_stop = fv_plex_stop;
  start_stop_struct.unified_filename = un_filename;
  
  shared_utils.io.require_dir( output_p );
  
  save( output_filename, 'start_stop_struct' );
end

end