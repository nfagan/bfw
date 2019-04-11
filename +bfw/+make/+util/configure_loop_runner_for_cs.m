function configure_loop_runner_for_cs(loop_runner)

loop_runner.get_directory_name_func = @bfw.make.util.cs_get_directory_name;
loop_runner.get_identifier_func = @(varargin) varargin{1}.cs_unified_filename;

end