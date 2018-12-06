function results = make_meta(varargin)

defaults = bfw.get_common_make_defaults();

inputs = 'unified';
output = 'meta';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );

loop_runner.func_name = mfilename;

results = loop_runner.run( @make_meta_main, params );

end

function meta_file = make_meta_main(files, unified_filename, params)

un_file = shared_utils.general.get( files, 'unified' );

meta_file = struct();
meta_file.unified_filename = unified_filename;
meta_file.date = un_file.m1.date;
meta_file.session = datestr( un_file.m1.date, 'mmddyyyy' );
meta_file.mat_filename = un_file.m1.mat_filename;
meta_file.task_type = bfw.field_or( un_file.m1, 'task_type', 'free_viewing' );

end