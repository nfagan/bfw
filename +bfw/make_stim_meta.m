function results = make_stim_meta(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'stim_meta';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.stim_meta );

end