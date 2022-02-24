function results = make_aligned_pupil_size(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'aligned_raw_indices', 'edf_raw_samples' };
output = 'aligned_raw_samples/pupil_size';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.aligned_pupil_size, params );

end