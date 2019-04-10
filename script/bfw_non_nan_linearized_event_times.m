function non_nan = bfw_non_nan_linearized_event_times(linearized_events)

start_times = linearized_events.events(:, linearized_events.event_key('start_time'));
stop_times = linearized_events.events(:, linearized_events.event_key('stop_time'));

non_nan = find( ~isnan(start_times) & ~isnan(stop_times) );

end