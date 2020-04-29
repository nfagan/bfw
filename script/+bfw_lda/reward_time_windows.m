% @T import mt.base
function [t_windows, t_window_names] = reward_time_windows()

t_windows = { [-0.25, 0], [0, 0.25], [0.05, 0.6] };
t_window_names = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };

end