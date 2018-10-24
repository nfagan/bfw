function add_raw_face_non_eyes(varargin)

defaults = bfw.get_common_make_defaults();
defaults.eyes_roi_name = 'eyes_nf';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
eyes_roi_name = params.eyes_roi_name;

in_bounds_p = bfw.gid( fullfile('raw_bounds', isd), conf );
out_bounds_p = bfw.gid( fullfile('raw_bounds', osd), conf );

mats = bfw.rim( params.files, in_bounds_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  bounds_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = bounds_file.unified_filename;
  output_filename = fullfile( out_bounds_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
    
    for j = 1:numel(monk_ids)
      monk_id = monk_ids{j};
      
      eyes = bounds_file.(monk_id).bounds(eyes_roi_name);
      face = bounds_file.(monk_id).bounds('face');
      
      face_non_eyes = face & ~eyes;
      face_non_eyes_roi_name = sprintf( 'face_non_%s', eyes_roi_name );
      
      bounds_file.(monk_id).bounds(face_non_eyes_roi_name) = face_non_eyes;
    end
    
    bounds_file.adjustments = containers.Map();
    bounds_file.adjustments('raw_face_non_eyes') = params;
    
    shared_utils.io.require_dir( out_bounds_p );
    shared_utils.io.psave( output_filename, bounds_file, 'bounds_file' );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
  end
end

end