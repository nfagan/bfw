function generate_reward_and_gaze_spikes(varargin)

make_defaults = bfw.get_common_make_defaults();
defaults = bfw.get_common_plot_defaults( make_defaults );
defaults.spike_dir = 'spikes';
defaults.non_eye_face_method = true;
defaults.events_subdir = 'raw_events';
defaults.gaze_rois = default_gaze_rois();
defaults.include_reward = true;
defaults.window_size = 0.05;
defaults.step_size = 0.05;

params = bfw.parsestruct( defaults, varargin );
pruned_params = prune_struct( params, make_defaults );

include_reward = params.include_reward;

save_p = get_save_path( params );

common_gaze_inputs = struct();
common_gaze_inputs.spike_func = 'spike_counts';
common_gaze_inputs.look_back = -1;
common_gaze_inputs.look_ahead = 1;
common_gaze_inputs.window_size = params.window_size;
common_gaze_inputs.step_size = params.step_size;
common_gaze_inputs.events_subdir = params.events_subdir;

if ( params.non_eye_face_method )
  gaze_counts_enef = bfw_gather_spikes_and_rng( ...
    common_gaze_inputs ...
    , 'rois', {'eyes_nf', 'face'} ...
    , 'non_overlapping_pairs', {{'eyes_nf', 'face'}} ...
    , pruned_params ...
    , 'spike_dir', params.spike_dir ...
  );

  gaze_counts_rest = bfw_gather_spikes_and_rng( ...
      common_gaze_inputs ...
    , 'rois', {'eyes_nf', 'face', 'left_nonsocial_object', 'right_nonsocial_object'} ...
    , 'collapse_nonsocial_object_rois', true ...
    , pruned_params ...
    , 'spike_dir', params.spike_dir ...
  );

  gaze_counts = combine_gaze_counts( gaze_counts_enef, gaze_counts_rest );
else
  gaze_counts = bfw_gather_spikes_and_rng( ...
    common_gaze_inputs ...
    , 'rois', params.gaze_rois ...
    , 'collapse_nonsocial_object_rois', true ...
    , pruned_params ...
    , 'spike_dir', params.spike_dir ...
    , 'is_already_non_overlapping', true ...
  );
end

if ( include_reward )
  reward_counts = bfw_get_cs_reward_response( ...
      'event_names', {'cs_target_acquire', 'cs_reward', 'cs_delay'} ...
    , 'look_back', -1 ...
    , 'look_ahead', 1 ...
    , 'is_firing_rate', false ...
    , pruned_params ...
    , 'spike_dir', params.spike_dir ...
  );
end

shared_utils.io.require_dir( save_p );
save( fullfile(save_p, 'gaze_counts.mat'), 'gaze_counts', '-v7.3' );

if ( include_reward )
  save( fullfile(save_p, 'reward_counts.mat'), 'reward_counts', '-v7.3' );
end

end

function gaze_counts = combine_gaze_counts(enef, rest)

face_ind = find( enef.labels, 'face' );
face_ind_events = find( enef.event_labels, 'face' );

setcat( enef.labels, 'roi', 'face_non_eyes', face_ind );
setcat( enef.event_labels, 'roi', 'face_non_eyes', face_ind_events );

gaze_counts = rest;
gaze_counts.labels = rest.labels';

append( gaze_counts.labels, enef.labels, face_ind );
gaze_counts.spikes = [ gaze_counts.spikes; enef.spikes(face_ind, :) ];

append( gaze_counts.event_labels, enef.event_labels, face_ind_events );
gaze_counts.events = [ gaze_counts.events; enef.events(face_ind_events, :) ];

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

function rois = default_gaze_rois()

rois = { 'eyes_nf', 'face', 'left_nonsocial_object_eyes_nf_matched' ...
    , 'right_nonsocial_object_eyes_nf_matched' };

end