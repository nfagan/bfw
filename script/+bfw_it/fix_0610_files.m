function fix_0610_files(varargin)

defaults = bfw.get_common_make_defaults();
defaults.date_str = '06102019';
defaults.task_str = 'image_control';
defaults.to_adjust = 3:13;

conf = defaults.config;
conf.PATHS.data_root = fullfile( conf.PATHS.mount, '/media/chang/T41/data/bfw/image-task/' );
defaults.config = conf;

params = bfw.parsestruct( defaults, varargin );

un_p = bfw.get_intermediate_directory( 'unified', params.config );

date_str = params.date_str;
task_str = params.task_str;
to_adjust = params.to_adjust;

for i = to_adjust
  unified_filename = sprintf( '%s_%s_%d.mat', date_str, task_str, i );
  full_path = fullfile( un_p, unified_filename );
  
  try
    unified_file = load( full_path );
  catch err
    warning( err.message );
    continue;
  end
  
  variable_name = char( fieldnames(unified_file) );
  unified_file = unified_file.(variable_name);
  
  unified_file.m1.plex_sync_index = i - to_adjust(1) + 1;
  
  save( full_path, 'unified_file' );
end

end