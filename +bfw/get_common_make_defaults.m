function defaults = get_common_make_defaults( assign_to )

%   GET_COMMON_MAKE_DEFAULTS -- Get common default values for bfw.make_* 
%     functions.
%
%     IN:
%       - `assign_to` (struct) |OPTIONAL|
%     OUT:
%       - `defaults` (struct)

if ( nargin == 0 )
  defaults = struct();
else
  validateattributes( assign_to, {'struct'}, {'scalar'}, mfilename, 'assign_to' );
  defaults = assign_to;
end

defaults.files = [];
defaults.files_containing = [];
defaults.files_not_containing = [];
defaults.loop_runner = [];
defaults.log_level = 'info';
defaults.cs_monk_id = 'm1';
defaults.input_subdir = '';
defaults.output_subdir = '';
defaults.overwrite = false;
defaults.append = true;
defaults.save = true;
defaults.is_parallel = true;
defaults.keep_output = false;
defaults.skip_existing = false;
defaults.main_error_handler = 'warn';
defaults.config = bfw.config.load();

end