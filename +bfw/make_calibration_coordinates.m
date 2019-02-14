function results = make_calibration_coordinates(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'edf';
output = 'calibration_coordinates';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.calibration_coordinates );

end