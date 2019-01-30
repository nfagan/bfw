function results = make_aligned_fixations(varargin)

defaults = bfw.make.defaults.aligned_fixations();
params = bfw.parsestruct( defaults, varargin );

fixations_subdir = params.fixations_subdir;

inputs = { 'aligned_raw_indices', fixations_subdir };
output = fullfile( 'aligned_raw_samples', fixations_subdir );

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.aligned_fixations, params );

end