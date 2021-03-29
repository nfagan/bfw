function out = bfw_load_cc_eye_interactive_events(conf)

if ( nargin < 1 )
  conf = bfw.config.load();
end

cc_events_file_path_eyes = ...
  fullfile( bfw.dataroot(conf), 'public', 'mutual_join_event_idx_and_labels.mat' );

cc_time_file_path = ...
  fullfile( bfw.dataroot(conf), 'public', 'behavior_time_for_interactive_alignment.mat' );

cc_events_file_eyes = load( cc_events_file_path_eyes );
cc_time_file = load( cc_time_file_path );

[event_inds, event_ts, event_labels] = ...
  bfw_extract_cc_interactive_event_info( cc_events_file_eyes, cc_time_file, 'eyes' );

out = struct();
out.indices = event_inds;
out.times = event_ts;
out.labels = event_labels;
out.cc_events_file = cc_events_file_eyes;
out.cc_time_file = cc_time_file;

end