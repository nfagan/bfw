function t_window = default_time_window_for_reward_event(event_name)

event_names = { 'cs_target_acquire', 'cs_reward', 'cs_delay', 'iti' };
time_windows = { [-0.25, 0], [0.05, 0.6], [0, 0.25], [0.5, 1] };

event_name = validatestring( event_name, event_names );

ind = strcmp( event_names, event_name );
t_window = time_windows{ind};

end