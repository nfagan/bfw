function population_decode_gaze_from_reward(gaze_counts, reward_counts, varargin)

defaults = bfw.get_common_make_defaults();
defaults.gaze_t_window = [ 0.1, 0.4];  % s
defaults.reward_t_window = [ 0.1, 0.4 ];  % s

params = bfw.parsestruct( defaults, varargin );

merged_data = merge_gaze_and_reward( gaze_counts, reward_counts, params );

end

function merged = merge_gaze_and_reward(gaze, reward, params)

gaze_t = gaze.t >= params.gaze_t_window(1) & gaze.t <= params.gaze_t_window(2);
rwd_t = reward.t >= params.reward_t_window(1) & reward.t <= params.reward_t_window(2);

average_gaze = nanmean( gaze.spikes(:, gaze_t), 2 );
average_rwd = nanmean( reward.psth(:, rwd_t), 2 );

end