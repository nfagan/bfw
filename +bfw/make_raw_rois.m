function make_raw_rois(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.rois = 'all';

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
  
  unified_file = shared_utils.io.fload( mats{i} );
  
  fields = fieldnames( unified_file );
  first_unified_file = unified_file.(fields{1});
  
  roi_pad = bfw.calibration.define_padding();
  roi_const = bfw.calibration.define_calibration_target_constants();
  
  mat_dir = first_unified_file.mat_directory_name;
  m_filename = first_unified_file.mat_filename;
  
  r_filename = bfw.make_intermediate_filename( mat_dir, m_filename );
  full_filename = fullfile( save_p, r_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  rois = struct();
  roi_funcs = get_roi_funcs(first_unified_file);
  
  try
    [roi_func_keys, is_all_rois] = get_active_roi_names( roi_funcs, params.rois );
  catch err
    bfw.print_fail_warn( m_filename, err.message );
    continue;
  end
  
  if ( ~is_all_rois && params.append )
    rois = try_get_current_rois( full_filename );
  end
  
  try
    for j = 1:numel(fields)
      m_id = fields{j};
      c_meta = unified_file.(m_id);
      
      %   either re-use the existing rect-map (if it exists)
      %   or create a new one.
      rect_map = get_rect_map( rois, m_id );

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
    shared_utils.io.psave( full_filename, rois, 'rois' );
    
  catch err
    bfw.print_fail_warn( r_filename, err.message );
    continue;
  end
end

end

function m = get_rect_map(rois, m_id)

if ( ~isfield(rois, m_id) || ~isfield(rois.(m_id), 'rects') )
  m = containers.Map();
else
  m = rois.(m_id).rects;
end

end

function [active, is_all] = get_active_roi_names(roi_funcs, roi_names)

roi_func_keys = roi_funcs.keys();
is_all = false;

if ( strcmpi(roi_names, 'all') )
  active = roi_func_keys;
  is_all = true;
  return
end

roi_names = unique( cellstr(roi_names) );

exists = ismember( roi_names, roi_func_keys );

if ( ~all(exists) )
  missing = roi_names( ~exists );
  missing_str = strjoin( missing, ', ' );
  
  error( 'Unrecognized roi names:\n\n %s\n', missing_str );
end

active = roi_names;

end

function r = try_get_current_rois(filename)

r = struct();

if ( ~shared_utils.io.fexists(filename) ), return; end

r = shared_utils.io.fload( filename );

end

function event_funcs = get_roi_funcs(un_file)

event_funcs = containers.Map();
event_funcs('face') =     @bfw.calibration.rect_face;
event_funcs('eyes_nf') =  @bfw.calibration.rect_eyes;
event_funcs('eyes') =     @bfw.calibration.rect_eyes_cc;
event_funcs('mouth') =    @bfw.calibration.rect_mouth_from_eyes;
event_funcs('outside1') = @bfw.calibration.rect_outside1;
event_funcs('outside2') = @bfw.calibration.rect_outside2;
% //
event_funcs('left_nonsocial_object') = @bfw.calibration.rect_left_nonsocial_object;
event_funcs('right_nonsocial_object') = @bfw.calibration.rect_right_nonsocial_object;

try
  r = un_file.stimulation_params.radius;
catch err
  warning( 'Missing radius parameter for: "%s".', un_file.unified_filename );
  return
end

event_funcs('face_padded_small') = @(varargin) bfw.calibration.rect_padded_face_small(varargin{:}, r);
event_funcs('face_padded_medium') = @(varargin) bfw.calibration.rect_padded_face_medium(varargin{:}, r);
event_funcs('face_padded_large') = @(varargin) bfw.calibration.rect_padded_face_large(varargin{:}, r);

end

function r = default_screen_rect()
r = [ 0, 0, 1024*3, 768 ];
end