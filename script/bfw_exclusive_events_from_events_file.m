function non_overlapping = bfw_exclusive_events_from_events_file(events_file, pairs, exclusive_each)

if ( nargin < 2 )
  pairs = bfw_get_non_overlapping_pairs();
end

if ( nargin < 3 )
  exclusive_each = {};
end

event_labels = fcat.from( events_file.labels, events_file.categories );
events = events_file.events;
event_key = events_file.event_key;

start_indices = events(:, event_key('start_index'));
stop_indices = events(:, event_key('stop_index'));

I = findall_or_one( event_labels, exclusive_each );

non_overlapping = bfw_exclusive_events( start_indices, stop_indices, event_labels, pairs, I );

end