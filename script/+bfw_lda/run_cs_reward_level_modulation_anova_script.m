event_file = bfw.load1( 'cs_task_events/m1', '01092019' );
trial_file = bfw.load1( 'cs_trial_data/m1', event_file.cs_unified_filename );
un_file = bfw.load1( 'cs_unified/m1', event_file.cs_unified_filename );

reward_level = trial_file.reward_levels;

reward_ind = strcmp( event_file.event_key, 'cs_reward' );

cs_on_t = event_file.event_times(:, strcmp(event_file.event_key, 'cs_presentation'));
cs_acq_t = event_file.event_times(:, strcmp(event_file.event_key, 'cs_target_acquire'));
cs_delay_t = event_file.event_times(:, strcmp(event_file.event_key, 'cs_delay'));
reward_ts = event_file.event_times(:, strcmp(event_file.event_key, 'cs_reward'));
iti_ts = event_file.event_times(:, strcmp(event_file.event_key, 'iti'));

is_success = ~isnan( reward_ts );
% diffs = cs_delay_t - cs_on_t;
% diffs = iti_ts - reward_ts;
% diffs = reward_ts - cs_delay_t;
diffs = reward_ts - cs_acq_t;

for i = 1:3
  ax = subplot( 1, 3, i );
  hist( diffs(is_success & reward_level == i), 100 );
  title( ax, sprintf('%0.2f', un_file.data.opts.REWARDS.single_pulse) );
end

%%

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'cs_reward', 'cs_target_acquire', 'fixation', 'iti', 'cs_presentation', 'cs_delay'} ...
  , 'look_back', 0 ...
  , 'look_ahead', 1.5 ...
  , 'is_firing_rate', false ...
  , 'include_rasters', false ...
);

%%

bfw_lda.run_cs_reward_level_modulation_anova( reward_counts );