%% Sort all events in ascending order by event time.

linearized_events = bfw_linearize_events();

%%  Ensure events are non-overlapping

event_labels = linearized_events.labels';
events = linearized_events.events;
event_key = linearized_events.event_key;

[mat_labels, mat_categories] = categorical( event_labels );

start_index_col = event_key('start_index');  
stop_index_col = event_key('stop_index');

start_indices = events(:, start_index_col);
stop_indices = events(:, stop_index_col);

rois = { 'eyes_nf', 'mouth', 'face' };
mask = find( event_labels, {'m1', 'm2', 'mutual'} );

I = findall( event_labels, {'unified_filename'}, mask );

non_overlapping = ...
  bfw_exclusiveize_events( start_indices, stop_indices, event_labels, rois, I );

non_overlapping_events = events(non_overlapping, :);
non_overlapping_labels = mat_labels(non_overlapping, :);

%%  Matlab native

roi_col = strcmp( mat_categories, 'roi' );
looks_by_col = strcmp( mat_categories, 'looks_by' );

is_eyes = mat_labels(non_overlapping, roi_col) == 'eyes_nf';
is_m1 = mat_labels(non_overlapping, looks_by_col) == 'm1';
is_m2 = mat_labels(non_overlapping, looks_by_col) == 'm2';

is_m1eyes = is_m1 & is_eyes;

%%  fcat

is_m1eyes_fcat = find( event_labels, {'m1', 'eyes_nf', '01162018'}, non_overlapping );






