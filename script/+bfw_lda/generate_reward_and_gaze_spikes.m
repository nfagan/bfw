function generate_reward_and_gaze_spikes(varargin)

make_defaults = bfw.get_common_make_defaults();
defaults = bfw.get_common_plot_defaults( make_defaults );

params = bfw.parsestruct( defaults, varargin );
pruned_params = prune_struct( params, make_defaults );

save_p = get_save_path( params );

gaze_counts = bfw_gather_spikes_and_rng( ...
  'spike_func', 'spike_counts' ...
  , 'look_back', -1 ...
  , 'look_ahead', 1 ...
  , pruned_params ...
);

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'cs_presentation', 'cs_reward', 'iti'} ...
  , 'look_back', -1 ...
  , 'look_ahead', 1 ...
  , 'is_firing_rate', false ...
  , pruned_params ...
);

shared_utils.io.require_dir( save_p );
save( fullfile(save_p, 'gaze_counts.mat'), 'gaze_counts', '-v7.3' );
save( fullfile(save_p, 'reward_counts.mat'), 'reward_counts', '-v7.3' );

end

function s1 = prune_struct(s1, s2)

keep_fields = intersect( fieldnames(s1), fieldnames(s2) );
rm_fields = setdiff( fieldnames(s1), keep_fields );
s1 = rmfield( s1, rm_fields );

end

function p = get_save_path(params)

p = fullfile( bfw.dataroot(params.config), 'analyses', 'spike_lda' ...
  , 'reward_gaze_spikes', params.base_subdir );

end