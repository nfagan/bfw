function [gaze_counts, rwd_counts] = load_gaze_reward_spikes(varargin)

base_counts_p = fullfile( bfw.dataroot(varargin{:}) ...
  , 'analyses/spike_lda/reward_gaze_spikes_tree' );

counts_p = fullfile( base_counts_p, 'counts_right_object_only' );

gaze_counts_file = fullfile( counts_p, 'gaze_counts.mat' );
rwd_counts_file = fullfile( counts_p, 'reward_counts.mat' );

gaze_counts = shared_utils.io.fload( gaze_counts_file );
rwd_counts = shared_utils.io.fload( rwd_counts_file );
replace( rwd_counts.labels, 'acc', 'accg' );

end