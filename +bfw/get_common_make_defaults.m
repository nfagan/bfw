function defaults = get_common_make_defaults( assign_to )

if ( nargin == 0 )
  defaults = struct();
else
  defaults = assign_to;
end

defaults.files = [];
defaults.files_containing = [];
defaults.loop_runner = [];
defaults.log_level = 'info';
defaults.cs_monk_id = 'm1';
defaults.input_subdir = '';
defaults.output_subdir = '';
defaults.overwrite = false;
defaults.append = true;
defaults.save = true;
defaults.is_parallel = true;
defaults.config = bfw.config.load();

end