function results = make_plex_raw_time(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'edf_raw_samples', 'edf_sync', 'unified', 'sync' };
output = 'plex_raw_time';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.plex_raw_time );

end