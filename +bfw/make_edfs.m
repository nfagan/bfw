function make_edfs(varargin)

defaults = struct();
defaults.files = [];
defaults.files_containing = [];

params = bfw.parsestruct( defaults, varargin );

conf = bfw.config.load();

data_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'edf' );

data_root = conf.PATHS.data_root;

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

copy_fields = { 'unified_filename', 'unified_directory' };

for i = 1:numel(mats)
  fprintf( '\n Processing %d of %d', i, numel(mats) );
  
  current = shared_utils.io.fload( mats{i} );
  fields = fieldnames( current );
  first = current.(fields{1});
  
  if ( isempty(first.edf_filename) )
    continue;
  end
  
  edf = struct();
  
  mat_dir = first.mat_directory_name;
  m_filename = first.mat_filename;
  e_filename = bfw.make_intermediate_filename( mat_dir, m_filename );
  
  is_valid_edf = true;
  
  for j = 1:numel(fields)
    m_dir = current.(fields{j}).mat_directory;
    edf_filename = current.(fields{j}).edf_filename;
    try
      edf_obj = Edf2Mat( fullfile(data_root, m_dir{:}, edf_filename) );
    catch err
      fprintf( '\n Error parsing edf file "%s": \n%s', edf_filename, err.message );
      is_valid_edf = false;
      continue;
    end
    edf.(fields{j}).edf = edf_obj;
    edf.(fields{j}).medf_filename = e_filename;
    edf.(fields{j}).medf_directory = save_p;
  end
  
  if ( ~is_valid_edf ), continue; end
  
  for j = 1:numel(copy_fields)
    for k = 1:numel(fields)
      edf.(fields{k}).(copy_fields{j}) = current.(fields{k}).(copy_fields{j});
    end
  end

  shared_utils.io.require_dir( save_p );
  save( fullfile(save_p, e_filename), 'edf' );
end

end