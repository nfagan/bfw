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
defaults.remove_nan_trials = true;
defaults.trial_average = false;
defaults.trial_average_specificity = {};
defaults.skip_matching_spike_lfp_regions = true;

defaults.chronux_params = struct( 'Fs', 1e3, 'tapers', [1.5, 2] );

defaults.keep_func = @identity_keep_func;

end

function [lfp_ind, spike_ind] = identity_keep_func(lfp_data, lfp_labels ...
  , spike_data, spike_labels)

lfp_ind = rowmask( lfp_data );
spike_ind = rowmask( spike_data );

end