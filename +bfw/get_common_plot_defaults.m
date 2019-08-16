function defaults = get_common_plot_defaults(append_to)

if ( nargin < 1 || isempty(append_to) )
  defaults = struct();
else
  defaults = append_to;
end

defaults.base_subdir = '';
defaults.do_save = false;
defaults.prefix = '';

end