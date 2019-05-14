base_load_p = fullfile( bfw.dataroot(), 'analyses/spike_lda/reward_gaze_spikes' );
base_perf_p = fullfile( base_load_p, 'performance/050119/' );

%%

gaze_counts = shared_utils.io.fload( fullfile(base_load_p, 'timecourse', 'gaze_counts.mat') );
reward_counts = shared_utils.io.fload( fullfile(base_load_p, 'timecourse', 'reward_counts.mat') );

%%

base_subdir = 'all-trials-matched-units-reward-reward-timecourse';

bfw_lda.run_decoding( gaze_counts, reward_counts, 'base_subdir', base_subdir );

%%

perf_file = fullfile( base_perf_p, base_subdir, 'performance.mat' );
perf = load( perf_file );

bfw_lda.plot_decoding( perf, 'base_subdir', base_subdir, 'do_save', true );

%%  time course

perf_file = fullfile( base_perf_p, base_subdir, 'performance.mat' );
perf = load( perf_file );

bfw_lda.plot_decoding_timecourse( perf, 'base_subdir', base_subdir, 'do_save', true );

%%

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'cs_presentation', 'cs_reward', 'iti'} ...
  , 'look_back', -1 ...
  , 'look_ahead', 1 ...
  , 'is_firing_rate', false ...
);

%%

tmp_counts = reward_counts;
pre_t = tmp_counts.t >= -0.4 & tmp_counts.t <= -0.1;
post_t = tmp_counts.t >= 0.1 & tmp_counts.t <= 0.4;
assert( nnz(post_t) == nnz(pre_t) );

cs_reward_ind = find( tmp_counts.labels, 'cs_reward' );

tmp_spikes = tmp_counts.psth(cs_reward_ind, :);
tmp_labels = prune( tmp_counts.labels(cs_reward_ind) );
tmp_levels = tmp_counts.reward_levels(cs_reward_ind);

setcat( tmp_labels, 'event-name', 'pre_cs_reward' );
tmp_spikes(:, post_t) = tmp_spikes(:, pre_t);

tmp_counts.psth = [ tmp_counts.psth; tmp_spikes ];
tmp_counts.labels = [ tmp_counts.labels'; tmp_labels ];
tmp_counts.reward_levels = [ tmp_counts.reward_levels; tmp_levels ];
tmp_counts.psth = tmp_counts.psth(:, post_t);
tmp_counts.t = tmp_counts.t(post_t);

prune( tmp_counts.labels );

base_subdir = 'all-trials-matched-units-pre-reward-strict-nonoverlapping';

bfw_lda.run_decoding( gaze_counts, tmp_counts, 'base_subdir', base_subdir );
