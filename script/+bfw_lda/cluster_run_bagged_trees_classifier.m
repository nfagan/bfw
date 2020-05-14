function cluster_run_bagged_trees_classifier(varargin)

defaults = struct();
defaults.config = bfw.config.load();
defaults.mask_func = @bfw.default_mask_func;
defaults.spike_func = @(x) nanmean( x, 2 );
% defaults.spike_func = @(x) max( x, [], 2 );
params = bfw.parsestruct( defaults, varargin );

conf = params.config;
base_counts_p = ...
  fullfile( bfw.dataroot(conf), 'analyses/spike_lda/reward_gaze_spikes_tree' );

% counts_p = fullfile( base_counts_p, 'counts' );
counts_p = fullfile( base_counts_p, 'counts_right_object_only' );

gaze_counts_file = fullfile( counts_p, 'gaze_counts.mat' );
rwd_counts_file = fullfile( counts_p, 'reward_counts.mat' );

gaze_counts = shared_utils.io.fload( gaze_counts_file );
rwd_counts = shared_utils.io.fload( rwd_counts_file );
replace( rwd_counts.labels, 'acc', 'accg' );

%%

mask_func = params.mask_func;
spike_func = params.spike_func;

outs = bfw_lda.bagged_trees_classifier( gaze_counts, rwd_counts ...
  , 'permutation_test_iters', 100 ...
  , 'permutation_test', true ...
  , 'reward_time_windows', {'cs_target_acquire'} ...
  , 'mask_func', mask_func ...
  , 'spike_func', spike_func ...
  , 'spike_criterion_func', @(varargin) bfw_lda.pnz_spike_criterion(varargin{:}, 0.3) ...
);

save_p = fullfile( base_counts_p, 'performance' );
shared_utils.io.require_dir( save_p );
filename = sprintf( '%s.mat', make_filename(outs.accuracy_labels) );
save( fullfile(save_p, filename), 'outs', '-v7.3' );

end

function file_name = make_filename(labels)

file_name = dsp3.fname( labels, {'region'} );

end