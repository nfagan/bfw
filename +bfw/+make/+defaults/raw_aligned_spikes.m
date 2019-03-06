function defaults = raw_aligned_spikes(varargin)

defaults = bfw.get_common_make_defaults( varargin{:} );
defaults.events_subdir = 'raw_events';
defaults.window_size = 150;
defaults.step_size = 50;
defaults.look_back = -500;
defaults.look_ahead = 500;
defaults.rois = 'all';
defaults.use_window_start_as_0 = false;
defaults.remove_rating_0_units = true;

end