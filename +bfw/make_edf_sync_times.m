function results = make_edf_sync_times(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'unified', 'edf' };
output = 'edf_sync';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.edf_sync_times );

end