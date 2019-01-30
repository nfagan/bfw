function results = make_binned_aligned_fixations(varargin)

defaults = bfw.make.defaults.binned_aligned_samples();
params = bfw.parsestruct( defaults, varargin );

inputs = fullfile( 'aligned_raw_samples', params.fixations_subdir );
output = fullfile( 'aligned_binned_raw_samples', params.fixations_subdir );

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.binned_aligned_fixations, params );

end