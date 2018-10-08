function make_raw_bounds(varargin)

ff = @fullfile;

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.padding = 0;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

samples_p = bfw.gid( ff('edf_raw_samples', isd), conf );
roi_p = bfw.gid( ff('rois', isd), conf );
bounds_p = bfw.gid( ff('raw_bounds', osd), conf );

mats = bfw.require_intermediate_mats( params.files, samples_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  samples_file = fload( mats{i} );
  
  unified_filename = samples_file.unified_filename;
  
  output_filename = fullfile( bounds_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    roi_file = fload( fullfile(roi_p, unified_filename) );
  catch err
    print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  fs = intersect( {'m1', 'm2'}, fieldnames(samples_file) );
  
  bounds_file = struct();
  bounds_file.unified_filename = unified_filename;
  bounds_file.params = params;
  
  try 
    for j = 1:numel(fs)
      m_id = fs{j};

      x = samples_file.(m_id).x;
      y = samples_file.(m_id).y;

      rects = roi_file.(m_id).rects;
      roi_names = keys( rects );
      
      bounds = containers.Map();
      
      for k = 1:numel(roi_names)
        roi = rects(roi_names{k});
        pad = params.padding;
        
        padded_roi = bfw.bounds.rect_pad_frac( roi, pad, pad );
        
        bounds(roi_names{k}) = bfw.bounds.rect( x, y, padded_roi );
      end
      
      bounds_file.(m_id).bounds = bounds;
    end
  catch err
    print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  shared_utils.io.require_dir( bounds_p );
  shared_utils.io.psave( output_filename, bounds_file, 'bounds_file' );
end

end

function print_fail_warn(un_file, msg)
warning( '"%s" failed: %s', un_file, msg );
end