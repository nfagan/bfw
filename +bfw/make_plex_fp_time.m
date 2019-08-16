function results = make_plex_fp_time(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'plex_fp_time';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.plex_fp_time, params.config );

end