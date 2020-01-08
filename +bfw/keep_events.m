function event_file = keep_events(event_file, ind)

event_file.labels = event_file.labels(ind, :);
event_file.events = event_file.events(ind, :);

end