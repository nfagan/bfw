% source_dir = '09062019_eyes_v_non_eyes_face';
source_dir = 'revisit_09032019';

base_load_p = fullfile( bfw.dataroot() ...
  , 'analyses/spike_lda/reward_gaze_spikes' ...
  , source_dir ...
);

gaze_counts = shared_utils.io.fload( fullfile(base_load_p, 'gaze_counts.mat') );

%%

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'cs_target_acquire', 'cs_delay', 'cs_reward', 'iti', 'fixation'} ...
  , 'look_back', -0.5 ...
  , 'look_ahead', 1.5 ...
  , 'is_firing_rate', false ...
  , 'include_rasters', false ...
);

%%

normalize_reward_counts = false;

event_names = { 'cs_target_acquire', 'cs_reward', 'cs_delay', 'iti' };
target_event_names = setdiff( event_names, 'iti' );

rc_time_windows = cellfun( @bfw_lda.default_time_window_for_reward_event, event_names, 'un', 0 );
gc_time_window = [0.05, 0.3];

rc = reward_counts;
rc_psth = bfw_lda.time_average_subsets( rc.psth, rc.labels, rc.t, event_names, rc_time_windows );

if ( normalize_reward_counts )
  rc_psth = bfw_lda.normalize_subsets( rc_psth, rc.labels, event_names, 'iti' );
end

rc.psth = rc_psth;

gc = struct();
gc.psth = nanmean( gaze_counts.spikes(:, gaze_counts.t >= gc_time_window(1) & gaze_counts.t <= gc_time_window(2)), 2 );
gc.labels = gaze_counts.labels';

%  time_average_subsets(data, labels, t, selector_combinations, t_windows, mask)

rc_mask = find( rc.labels, target_event_names );
gc_mask = rowmask( gc.psth );

bfw_lda.modulation_index_vs_decoding_performance( rc.psth, rc.labels, rc_mask, gc.psth, gc.labels, gc_mask ...
  , 'do_save', true ...
  , 'rng_seed', 1 ...
);