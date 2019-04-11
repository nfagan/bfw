function results = make_cs_trial_data(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'cs_unified/m1';
output = 'cs_trial_data/m1';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

loop_runner.get_directory_name_func = @bfw.make.util.cs_get_directory_name;
loop_runner.func_name = mfilename;
loop_runner.get_identifier_func = @(varargin) varargin{1}.cs_unified_filename;

results = loop_runner.run( @bfw.make.cs_trial_data );

end