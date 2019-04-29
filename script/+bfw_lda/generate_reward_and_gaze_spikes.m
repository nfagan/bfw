function generate_reward_and_gaze_spikes(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

save_p = get_save_path( params.config );

gaze_counts = bfw_gather_spikes_and_rng( ...
  'spike_func', 'spike_counts' ...
  , params ...
);

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'cs_presentation', 'cs_reward', 'iti'} ...
  , 'look_back', 0 ...
  , 'look_ahead', 1 ...
  , 'is_firing_rate', false ...
  , params ...
);

shared_utils.io.require_dir( save_p );
save( fullfile(save_p, 'gaze_counts.mat'), 'gaze_counts', '-v7.3' );
save( fullfile(save_p, 'reward_counts.mat'), 'reward_counts', '-v7.3' );

end

function p = get_save_path(conf)

p = fullfile( bfw.dataroot(conf), 'analyses', 'spike_lda', 'reward_gaze_spikes' );

end