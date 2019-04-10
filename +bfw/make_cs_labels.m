function results = make_cs_labels(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'cs_unified/m1', 'meta' };
output = 'cs_labels/m1';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.get_directory_name_func = @bfw.make.util.cs_get_directory_name;
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.cs_labels );

end