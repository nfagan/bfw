function make_cs_edfs(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;
mid = params.cs_monk_id;

data_p = bfw.get_intermediate_directory( fullfile('cs_unified', mid, isd), conf );
save_p = bfw.get_intermediate_directory( fullfile('cs_edf', mid, osd), conf );

data_root = conf.PATHS.data_root;

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

for i = 1:numel(mats)
  fprintf( '\n Processing %d of %d', i, numel(mats) );
  
  current = shared_utils.io.fload( mats{i} );
  
  edf_file = struct();
  
  un_filename = current.cs_unified_filename;
  full_filename = fullfile( save_p, un_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  m_dir = current.mat_directory;
  edf_filename = current.edf_filename;
  
  try
    edf_obj = Edf2Mat( fullfile(data_root, m_dir{:}, edf_filename) );
  catch err
    fprintf( '\n Error parsing edf file "%s": \n%s', edf_filename, err.message );
    continue;
  end
  
  edf_file.edf = edf_obj;
  edf_file.cs_unified_filename = un_filename;
  
  shared_utils.io.require_dir( save_p );
  save( full_filename, 'edf_file' );
end

end