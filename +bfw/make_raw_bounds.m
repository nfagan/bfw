function results = make_raw_bounds(varargin)

defaults = bfw.get_common_make_defaults();
defaults.padding = 0;

inputs = { 'edf_raw_samples', 'rois' };
output = 'raw_bounds';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @make_raw_bounds_main, params );

end

function bounds_file = make_raw_bounds_main(files, unified_filename, params)

samples_file = shared_utils.general.get( files, 'edf_raw_samples' );
roi_file = shared_utils.general.get( files, 'rois' );

fs = intersect( {'m1', 'm2'}, fieldnames(samples_file) );

bounds_file = struct();
bounds_file.unified_filename = unified_filename;
bounds_file.params = params;

for j = 1:numel(fs)
  m_id = fs{j};

  x = samples_file.(m_id).x;
  y = samples_file.(m_id).y;

  rects = roi_file.(m_id).rects;
  roi_names = keys( rects );

  bounds = containers.Map();

  for k = 1:numel(roi_names)
    roi_name = roi_names{k};

    roi = rects(roi_name);
    pad = get_padding( params.padding, roi_name );

    padded_roi = bfw.bounds.rect_pad_frac( roi, pad, pad );

    bounds(roi_names{k}) = bfw.bounds.rect( x, y, padded_roi );
  end

  bounds_file.(m_id).bounds = bounds;
end

end

function p = get_padding(padding, roi)

if ( isnumeric(padding) )
  p = padding;
  return
end

if ( shared_utils.general.is_key(padding, roi) )
  p = shared_utils.general.get( padding, roi );
else
  p = 0;
end

end