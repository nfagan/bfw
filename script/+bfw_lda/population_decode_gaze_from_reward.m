function population_decode_gaze_from_reward(gaze_counts, reward_counts, varargin)

defaults = bfw.get_common_make_defaults();
defaults.gaze_t_window = [ 100, 400 ];  % ms
defaults.reward_t_window = [ 0.1, 0.4 ];  % s

params = bfw.parsestruct( defaults, varargin );

merged_data = merge_gaze_and_reward( gaze_counts, reward_counts, params );

end

function merged = merge_gaze_and_reward(gaze, reward, params)

d = 10;

end