function rois = rois(files, output_directory, varargin)

%   ROIS -- Create rois file.
%
%     See also bfw.make.help, bfw.make.defaults.rois
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `output_directory` (char)
%       - `varargin` ('name', value)
%     FILES:
%       - 'unified'
%     OUT:
%       - `aligned_file` (struct)

bfw.validatefiles( files, 'unified' );

defaults = bfw.make.defaults.rois();
params = bfw.parsestruct( defaults, varargin );

unified_file = shared_utils.general.get( files, 'unified' );
unified_filename = bfw.try_get_unified_filename( unified_file );
  
fields = fieldnames( unified_file );
first_unified_file = unified_file.(fields{1});

roi_pad = bfw.calibration.define_padding();
roi_const = bfw.calibration.define_calibration_target_constants();

rois = struct();
roi_funcs = get_roi_funcs(first_unified_file);

[roi_func_keys, is_all_rois] = get_active_roi_names( roi_funcs, params.rois );

if ( ~is_all_rois && params.append )
  rois = try_get_current_rois( fullfile(output_directory, unified_filename) );
end

copy_fields = { 'unified_filename', 'unified_directory' };

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
    warning( 'Missing calibration data for file: "%s".', unified_filename );
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

  rois.(m_id).roi_filename = unified_filename;
  rois.(m_id).roi_directory = output_directory;
  rois.(m_id).rects = rect_map;
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

function roi_funcs = get_roi_funcs(un_file)

roi_funcs = containers.Map();
roi_funcs('face') =         @bfw.calibration.rect_face;
roi_funcs('eyes_nf') =      @bfw.calibration.rect_eyes;
roi_funcs('eyes') =         @bfw.calibration.rect_eyes_cc;
roi_funcs('mouth') =        @bfw.calibration.rect_mouth_inverted_eyes;
roi_funcs('everywhere') =   @bfw.calibration.rect_everywhere;
roi_funcs('outside1') =     @bfw.calibration.rect_outside1;
roi_funcs('outside2') =     @bfw.calibration.rect_outside2;
% //
roi_funcs('left_nonsocial_object') = @bfw.calibration.rect_left_nonsocial_object;
roi_funcs('right_nonsocial_object') = @bfw.calibration.rect_right_nonsocial_object;
roi_funcs('right_middle_nonsocial_object') = @bfw.calibration.rect_right_middle_nonsocial_object;

% //
roi_funcs('top_eyes') =         @bfw.calibration.rect_top_eyes;
roi_funcs('bottom_mouth') =     @bfw.calibration.rect_bottom_mouth;

roi_funcs('top_object1') =      @bfw.calibration.rect_top_object1;
roi_funcs('top_object2') =      @bfw.calibration.rect_top_object2;
roi_funcs('bottom_object1') =   @bfw.calibration.rect_bottom_object1;
roi_funcs('bottom_object2') =   @bfw.calibration.rect_bottom_object2;
roi_funcs('left_nonsocial_object_eyes_nf_matched') = @bfw.calibration.rect_left_nonsocial_object_eyes_nf_matched;
roi_funcs('right_nonsocial_object_eyes_nf_matched') = @bfw.calibration.rect_right_nonsocial_object_eyes_nf_matched;

try
  r = un_file.stimulation_params.radius;
catch err
  warning( 'Missing radius parameter for: "%s".', un_file.unified_filename );
  return
end

roi_funcs('face_padded_small') = @(varargin) bfw.calibration.rect_padded_face_small(varargin{:}, r);
roi_funcs('face_padded_medium') = @(varargin) bfw.calibration.rect_padded_face_medium(varargin{:}, r);
roi_funcs('face_padded_large') = @(varargin) bfw.calibration.rect_padded_face_large(varargin{:}, r);

end

function r = default_screen_rect()
r = [ 0, 0, 1024*3, 768 ];
end