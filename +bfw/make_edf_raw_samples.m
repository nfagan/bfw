function make_edf_raw_samples(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

edf_p = bfw.gid( ff('edf', isd), conf );
save_p = bfw.gid( ff('edf_raw_position', osd), conf );

mats = bfw.require_intermediate_mats( params.files, edf_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  edf_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = edf_file.m1.unified_filename;
  output_filename = fullfile( save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  m_fields = fieldnames( edf_file );
  
  position_file = struct();
  position_file.unified_filename = unified_filename;
  
  for j = 1:numel(m_fields)
    m_str = m_fields{j};
    
    edf = edf_file.(m_str).edf;
    
    x = edf.Samples.posX;
    y = edf.Samples.posY;
    t = edf.Samples.time;
    ps = edf.Samples.pupilSize;
    
    position_file.(m_str).x = x;
    position_file.(m_str).y = y;
    position_file.(m_str).t = t;
    position_file.(m_str).pupil = ps;
  end
  
  shared_utils.io.require_dir( save_p );
  shared_utils.io.psave( output_filename, position_file, 'position' );
end

end