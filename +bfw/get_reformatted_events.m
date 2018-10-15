function new_evts_file = get_reformatted_events(events_file)

new_evts_file = struct();
new_evts_file.unified_filename = events_file.unified_filename;

monk_ids = keys( events_file.monk_key );
roi_ids = keys( events_file.roi_key );

C = combvec( 1:numel(monk_ids), 1:numel(roi_ids) );

new_events = [];
new_labels = {};

for i = 1:size(C, 2)
  monk_idx = C(1, i);
  roi_idx = C(2, i);
  
  monk_id = monk_ids{monk_idx};
  roi_id = roi_ids{roi_idx};
  
  mat_roi_idx = events_file.roi_key(roi_id);
  mat_monk_idx = events_file.monk_key(monk_id);
  
  subset_times = events_file.times{mat_roi_idx, mat_monk_idx};
  subset_lengths = events_file.lengths{mat_roi_idx, mat_monk_idx};
  subset_durations = events_file.durations{mat_roi_idx, mat_monk_idx};  
  
  event_info = [ subset_times(:), subset_lengths(:), subset_durations(:) ];
  new_events = [ new_events; event_info ];
  
  c_labs = { monk_id, '<initiator>', '<event_type>', roi_id };  
  c_labs = repmat( c_labs, size(event_info, 1), 1 );
  
  new_labels = [ new_labels; c_labs ];
end

event_key = containers.Map();
event_key('start_time') = 1;
event_key('length') = 2;
event_key('duration') = 3;

new_evts_file.labels = new_labels;
new_evts_file.categories = { 'looks_by', 'initiator', 'event_type', 'roi' };
new_evts_file.events = new_events;
new_evts_file.event_key = event_key;
new_evts_file.params = events_file.params;
new_evts_file.params.step_size = events_file.step_size;

end