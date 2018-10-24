function defaults = get_common_make_defaults( assign_to )

if ( nargin == 0 )
  defaults = struct();
else
  defaults = assign_to;
end

defaults.files = [];
defaults.files_containing = [];
defaults.cs_monk_id = 'm1';
defaults.input_subdir = '';
defaults.output_subdir = '';
defaults.overwrite = false;
defaults.append = true;
defaults.save = true;
defaults.config = bfw.config.load();

end