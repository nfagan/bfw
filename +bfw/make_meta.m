function make_meta(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

unified_p = bfw.gid( fullfile(params.input_subdir, 'unified'), conf );
meta_p = bfw.gid( fullfile(params.output_subdir, 'meta'), conf );

mats = bfw.require_intermediate_mats( params.files, unified_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  un_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = un_file.m1.unified_filename;
  
  output_filename = fullfile( meta_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  meta_file = struct();
  meta_file.unified_filename = unified_filename;
  meta_file.date = un_file.m1.date;
  meta_file.session = datestr( un_file.m1.date, 'mmddyyyy' );
  meta_file.mat_filename = un_file.m1.mat_filename;
  meta_file.task_type = bfw.field_or( un_file.m1, 'task_type', 'free_viewing' );
  
  shared_utils.io.require_dir( meta_p );
  shared_utils.io.psave( output_filename, meta_file, 'meta_file' );
end

end