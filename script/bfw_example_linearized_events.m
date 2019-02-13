linearized_events = bfw_linearize_events();

%%

event_labels = linearized_events.labels';
events = linearized_events.events;
event_key = linearized_events.event_key;

start_index_col = event_key('start_index');  
stop_index_col = event_key('stop_index');

start_indices = events(:, start_index_col);
stop_indices = events(:, stop_index_col);

rois = { 'eyes_nf', 'mouth', 'face' };
mask = find( event_labels, {'m1', 'm2'} );

I = findall( event_labels, {'unified_filename'}, mask );

non_overlapping = ...
  bfw_exclusiveize_events( start_indices, stop_indices, event_labels, rois, I );
