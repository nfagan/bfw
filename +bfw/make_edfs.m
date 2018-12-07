function results = make_edfs(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'edf';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

out_dir = loop_runner.output_directory;
conf = params.config;

results = loop_runner.run( @bfw.make.edfs, out_dir, conf );

end