function results = make_raw_events(varargin)

defaults = bfw.make.defaults.raw_events();

params = bfw.parsestruct( defaults, varargin );

fixations_subdir = params.fixations_subdir;
samples_subdir = params.samples_subdir;

inputs = { 'time', 'bounds', 'position', fixations_subdir };
inputs = cellfun( @(x) fullfile(samples_subdir, x), inputs, 'un', 0 );
inputs = [ 'rois', inputs ];

output = 'raw_events';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.raw_events, params );

end