function make_rois(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = bfw.config.load();

data_p = fullfile( conf.PATHS.data_root, 'intermediates', 'unified' );

save_p = fullfile( conf.PATHS.data_root, 'intermediates', 'rois' );

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

event_funcs = containers.Map();
event_funcs('face') = @bfw.calibration.rect_face;
event_funcs('eyes') = @bfw.calibration.rect_eyes;

copy_fields = { 'unified_filename', 'unified_directory' };

for i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  meta = shared_utils.io.fload( mats{i} );
  
  fields = fieldnames( meta );
  
%   roi_map = bfw.calibration.get_calibration_key_roi_map();
  roi_map = meta.(fields{1}).far_plane_key_map;
  roi_pad = bfw.calibration.define_padding();
  roi_const = bfw.calibration.define_calibration_target_constants();
  
  event_func_keys = event_funcs.keys();
  
  rois = struct();
  
  mat_dir = meta.(fields{1}).mat_directory_name;
  m_filename = meta.(fields{1}).mat_filename;
  
  r_filename = bfw.make_intermediate_filename( mat_dir, m_filename );
  full_filename = fullfile( save_p, r_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  for j = 1:numel(fields)
    rect_map = containers.Map();
    calibration = meta.(fields{j}).far_plane_calibration;
    for k = 1:numel(event_func_keys)
      key = event_func_keys{k};
      func = event_funcs(key);
      rect = func( calibration, roi_map, roi_pad, roi_const );
      rect_map(key) = rect;
    end
    for k = 1:numel(copy_fields)
      rois.(fields{j}).(copy_fields{k}) = meta.(fields{j}).(copy_fields{k});
    end
    rois.(fields{j}).roi_filename = r_filename;
    rois.(fields{j}).roi_directory = save_p;
    rois.(fields{j}).rects = rect_map;
  end  
  
  shared_utils.io.require_dir( save_p );
  save( full_filename, 'rois' );
end

end