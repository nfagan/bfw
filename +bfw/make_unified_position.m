function results = make_unified_position(varargin)

defaults = bfw.get_common_make_defaults();
defaults.samples_subdir = 'aligned_raw_samples';

params = bfw.parsestruct( defaults, varargin );

samples_subdir = validatestring( params.samples_subdir ...
  , {'aligned_raw_samples', 'aligned_binned_raw_samples'} );

inputs = { 'unified', fullfile(samples_subdir, 'position') };
output = fullfile( samples_subdir, 'unified_position' );

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = loop_runner.run( @bfw.make.unified_position );

end