function results = make_aligned_bounds(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'aligned_raw_indices', 'raw_bounds' };
output = 'aligned_raw_samples/bounds';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.aligned_bounds, params );

end