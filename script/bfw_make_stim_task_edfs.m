function results = bfw_make_stim_task_edfs(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw.set_dataroot( get_data_root(defaults.config) );
defaults.skip_existing = true;

params = bfw.parsestruct( defaults, varargin );

results = bfw.make_edfs( params );

end