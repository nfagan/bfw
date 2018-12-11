function results = make_raw_bounds(varargin)

defaults = bfw.make.defaults.raw_bounds();

inputs = { 'edf_raw_samples', 'rois' };
output = 'raw_bounds';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.bounds, params );

end