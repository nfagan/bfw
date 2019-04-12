function non_overlapping = bfw_exclusive_events_from_linearized_events(linearized_events, pairs)

if ( nargin < 2 )
  pairs = bfw_get_non_overlapping_pairs();
end

if ( isfield(linearized_events, 'labels') && ~isa(linearized_events.labels, 'fcat') )
  event_labels = fcat.from( linearized_events );
else
  event_labels = linearized_events.labels';
end

events = linearized_events.events;
event_key = linearized_events.event_key;

start_indices = events(:, event_key('start_index'));
stop_indices = events(:, event_key('stop_index'));

I = findall( event_labels, 'unified_filename' );

non_overlapping = bfw_exclusive_events( start_indices, stop_indices, event_labels, pairs, I );

end