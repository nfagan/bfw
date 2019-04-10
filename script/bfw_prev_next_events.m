function outs = bfw_prev_next_events(linearized_events, rois, mask)

event_labels = linearized_events.labels;
start_times = linearized_events.events(:, linearized_events.event_key('start_time'));

if ( nargin < 3 )
  mask = rowmask( event_labels );
end

I = findall( event_labels, 'unified_filename', mask );

[prev_labs, prev_event_intervals] = bfw_label_n_minus_n_events( start_times, event_labels', I ...
  , 'previous_category_names', {'roi', 'looks_by'} ...
  , 'mask_inputs', {@find, rois} ...
);

[next_labs, next_event_intervals] = bfw_label_n_plus_n_events( start_times, event_labels', I ...
  , 'next_category_names', {'roi', 'looks_by'} ...
  , 'mask_inputs', {@find, rois} ...
);

prune( prev_labs );
prune( next_labs );

outs.prev_intervals = prev_event_intervals;
outs.prev_labels = prev_labs;
outs.next_intervals = next_event_intervals;
outs.next_labels = next_labs;

end