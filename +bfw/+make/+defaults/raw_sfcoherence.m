function defaults = raw_sfcoherence(varargin)

lfp_defaults = bfw.get_common_lfp_defaults( varargin{:} );
defaults = bfw.get_common_make_defaults( lfp_defaults );

defaults.look_back = -500;
defaults.look_ahead = 500;
defaults.window_size = 150;
defaults.step_size = 50;
defaults.sample_rate = 1000;

defaults.lfp_subdir = 'lfp';
defaults.spike_subdir = 'spikes';
defaults.events_subdir = 'raw_events';

defaults.rois = 'all';

end