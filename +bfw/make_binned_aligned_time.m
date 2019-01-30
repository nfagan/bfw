function results = make_binned_aligned_time(varargin)

defaults = bfw.make.defaults.binned_aligned_samples();

inputs = 'aligned_raw_samples/time';
output = 'aligned_binned_raw_samples/time';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.binned_aligned_time, params );

end