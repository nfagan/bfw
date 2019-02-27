function defaults = raw_aligned_lfp(varargin)

defaults = bfw.get_common_make_defaults( varargin{:} );
defaults.events_subdir = 'raw_events';
defaults.window_size = 150;
defaults.look_back = -500;
defaults.look_ahead = 500;
defaults.sample_rate = 1000;

end