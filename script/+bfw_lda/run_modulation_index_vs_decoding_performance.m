%%

gaze_counts = bfw_lda.load_gaze_counts_all_rois();

%%

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'cs_target_acquire', 'cs_delay', 'cs_reward', 'iti', 'fixation'} ...
  , 'look_back', -0.5 ...
  , 'look_ahead', 1.5 ...
  , 'is_firing_rate', false ...
  , 'include_rasters', false ...
  , 'is_parallel', true ...
);

%%

all_spikes = bfw_gather_spikes();
session_times = bfw_get_plex_start_stop();

%%

window_size = 10;

[windows, is_empty_window, empty_window_labels] = ...
  bfw.identify_empty_windows( all_spikes.spike_times, all_spikes.labels ...
  , session_times.start_stops, session_times.labels, window_size );

%%

gaze_data_type = 'nfix';
use_window_criterion = false;
median_split_duration = false;

components = bfw_lda.make_gaze_reward_components( gaze_counts, gaze_data_type, reward_counts ...
  , 'windows', windows ...
  , 'is_empty_window', is_empty_window ...
  , 'empty_window_labels', empty_window_labels ...
  , 'use_empty_window_criterion', use_window_criterion ...
  , 'median_split_duration', median_split_duration ...
  , 'nfix_window_duration', 5 ...
);

rc = components.rc;
rc_mask = components.rc_mask;
gc = components.gc;
gc_mask = components.gc_mask;
gc_spikes = components.gc_spikes;
gc_spike_mask = components.gc_spike_mask;

%%  reward / gaze

bfw_lda.modulation_index_vs_decoding_combinations( rc, rc_mask, gc, gc_mask ...
  , 'a_is', 'reward' ...
  , 'b_is', 'gaze' ...
  , 'kinds', {'b/a'} ...
  , 'plot', false ...
  , 'permutation_test', true ...
);

%%  gaze / gaze

additional_each = ternary( median_split_duration, {'duration_quantile'}, {} );
split_subdir = ternary( median_split_duration, '-median-split', '' );
crit_subdir = ternary( use_window_criterion, 'with_exclusion_criteria', 'no_exclusion_criteria' );

base_subdir = sprintf('%s%s', crit_subdir, split_subdir );

bfw_lda.modulation_index_vs_decoding_combinations( gc, gc_mask, gc_spikes, gc_spike_mask ...
  , 'a_is', 'gaze' ...
  , 'b_is', 'gaze' ...
  , 'kinds', {'a/b'} ...
  , 'additional_each', additional_each ...
  , 'base_subdir', sprintf('%s/', base_subdir) ...
  , 'use_multi_regression', true ...
);

%%  reward / gaze, duration quantile

[quant_I, quant_C] = findall( gc.labels, 'duration_quantile', gc_mask );

for i = 1:numel(quant_I)
  bfw_lda.modulation_index_vs_decoding_combinations( rc, rc_mask, gc, quant_I{i} ...
    , 'a_is', 'reward' ...
    , 'b_is', 'gaze' ...
    , 'kinds', {'b/a'} ...
    , 'base_subdir', sprintf('%s-', strjoin(quant_C(:, i), '-')) ...
  );
end