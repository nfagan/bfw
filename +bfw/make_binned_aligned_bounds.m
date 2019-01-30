function results = make_binned_aligned_bounds(varargin)

defaults = bfw.make.defaults.binned_aligned_samples();

inputs = 'aligned_raw_samples/bounds';
output = 'aligned_binned_raw_samples/bounds';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.binned_aligned_bounds, params );

end