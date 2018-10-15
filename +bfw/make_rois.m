function make_rois(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

data_p = bfw.gid( ff('unified', isd), conf );
save_p = bfw.gid( ff('rois', osd), conf );

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

copy_fields = { 'unified_filename', 'unified_directory' };

for i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  meta = shared_utils.io.fload( mats{i} );
  
  fields = fieldnames( meta );
  
  roi_pad = bfw.calibration.define_padding();
  roi_const = bfw.calibration.define_calibration_target_constants();
  
  roi_funcs = get_roi_funcs(meta.(fields{1}));
  roi_func_keys = roi_funcs.keys();
  
  rois = struct();
  
  mat_dir = meta.(fields{1}).mat_directory_name;
  m_filename = meta.(fields{1}).mat_filename;
  
  r_filename = bfw.make_intermediate_filename( mat_dir, m_filename );
  full_filename = fullfile( save_p, r_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  for j = 1:numel(fields)
    m_id = fields{j};
    c_meta = meta.(m_id);
    
    rect_map = containers.Map();
    roi_map = c_meta.far_plane_key_map;
    calibration = c_meta.far_plane_calibration;
    screen_rect = bfw.field_or( c_meta, 'screen_rect', default_screen_rect() );
    
    if ( isequaln(calibration, nan) || isequaln(roi_map, nan) )
      warning( 'Missing calibration data for file: "%s".', r_filename );
      continue;
    end
    
    for k = 1:numel(roi_func_keys)
      key = roi_func_keys{k};
      func = roi_funcs(key);
      rect = func( calibration, roi_map, roi_pad, roi_const, screen_rect );
      rect_map(key) = rect;
    end
    
    for k = 1:numel(copy_fields)
      rois.(m_id).(copy_fields{k}) = c_meta.(copy_fields{k});
    end
    
    rois.(m_id).roi_filename = r_filename;
    rois.(m_id).roi_directory = save_p;
    rois.(m_id).rects = rect_map;
  end  
  
  shared_utils.io.require_dir( save_p );
  save( full_filename, 'rois' );
end

end

function event_funcs = get_roi_funcs(un_file)

event_funcs = containers.Map();
event_funcs('face') =     @bfw.calibration.rect_face;
event_funcs('eyes_nf') =  @bfw.calibration.rect_eyes;
event_funcs('eyes') =     @bfw.calibration.rect_eyes_cc;
event_funcs('mouth') =    @bfw.calibration.rect_mouth_from_eyes;
event_funcs('outside1') = @bfw.calibration.rect_outside1;
event_funcs('outside2') = @bfw.calibration.rect_outside2;

try
  r = un_file.stimulation_params.radius;
catch err
  warning( 'Missing radius parameter for: "%s".', un_file.unified_filename );
  return;
end

event_funcs('face_padded_small') = @(varargin) bfw.calibration.rect_padded_face_small(varargin{:}, r);
event_funcs('face_padded_medium') = @(varargin) bfw.calibration.rect_padded_face_medium(varargin{:}, r);
event_funcs('face_padded_large') = @(varargin) bfw.calibration.rect_padded_face_large(varargin{:}, r);

end

function r = default_screen_rect()
r = [ 0, 0, 1024*3, 768 ];
end