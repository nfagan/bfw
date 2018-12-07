function results = make_edf_raw_samples(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'edf';
output = 'edf_raw_samples';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.edf_raw_samples );

end