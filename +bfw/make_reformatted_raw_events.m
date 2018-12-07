function results = make_reformatted_raw_events(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'raw_events';
output = 'raw_events_reformatted';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.reformatted_events, params );

end