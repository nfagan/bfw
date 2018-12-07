function results = make_raw_rois(varargin)

defaults = bfw.get_common_make_defaults();
defaults.rois = 'all';

inputs = 'unified';
output = 'rois';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

out_dir = loop_runner.output_directory;

results = loop_runner.run( @bfw.make.rois, out_dir, params );

end