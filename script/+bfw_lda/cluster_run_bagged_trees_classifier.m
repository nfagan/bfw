conf = bfw.config.load();

base_counts_p = fullfile( bfw.dataroot(conf), 'analyses/spike_lda/reward_gaze_spikes_tree' );

% counts_p = fullfile( base_counts_p, 'counts' );
counts_p = fullfile( base_counts_p, 'counts_right_object_only' );

gaze_counts_file = fullfile( counts_p, 'gaze_counts.mat' );
rwd_counts_file = fullfile( counts_p, 'reward_counts.mat' );

gaze_counts = shared_utils.io.fload( gaze_counts_file );
rwd_counts = shared_utils.io.fload( rwd_counts_file );
replace( rwd_counts.labels, 'acc', 'accg' );

%%

mask_func = @(l, m) m;

outs = bfw_lda.bagged_trees_classifier( gaze_counts, rwd_counts ...
  , 'permutation_test_iters', 100 ...
  , 'permutation_test', true ...
  , 'reward_time_windows', 'cs_target_acquire' ...
  , 'mask_func', mask_func ...
);