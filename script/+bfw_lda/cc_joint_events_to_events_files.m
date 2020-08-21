function [event_files, I] = cc_joint_events_to_events_files(events, labels, params)

assert_ispair( events, labels );
[I, unified_filenames] = findall( labels, 'unified_filename' );

event_files = cell( size(I) );

for i = 1:numel(I)
  evts = events(I{i}, :);
  labs = prune( labels(I{i}) );
  unified_filename = unified_filenames{i};
  
  event_file = struct();
  event_file.events = evts;
  event_file.labels = cellstr( labs );
  event_file.categories = categories( labs );
  event_file.unified_filename = unified_filename;
  event_file.event_key = containers.Map();
  event_file.event_key('start_time') = 1;
  event_file.params = params;
  
  event_files{i} = event_file;
end

end