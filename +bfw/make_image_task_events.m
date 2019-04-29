function results = make_image_task_events(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'unified', 'sync' };
output = 'image_task_events';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @bfw.make.image_task_events );

end