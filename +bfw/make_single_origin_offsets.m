function results = make_single_origin_offsets(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'calibration_coordinates';
output = 'single_origin_offsets';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

results = loop_runner.run( @bfw.make.single_origin_offsets );

end