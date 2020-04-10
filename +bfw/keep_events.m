function event_file = keep_events(event_file, ind, preserve_label_class)

if ( nargin < 3 )
  preserve_label_class = false;
end

if ( preserve_label_class )
  event_file.labels = event_file.labels(ind);
else
  event_file.labels = event_file.labels(ind, :);
end

event_file.events = event_file.events(ind, :);

end