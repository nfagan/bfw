function results = make_raw_aligned_indices(varargin)

defaults = bfw.make.defaults.raw_aligned_indices();

inputs = 'plex_raw_time';
output = 'aligned_raw_indices';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.raw_aligned_indices, params );

end