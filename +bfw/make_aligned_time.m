function results = make_aligned_time(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'aligned_raw_indices';
output = 'aligned_raw_samples/time';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.aligned_time, params );

end