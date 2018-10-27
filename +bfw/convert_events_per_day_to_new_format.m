function out_file = convert_events_per_day_to_new_format(events_file, unified_filename)

event_info = only( events_file.event_info, unified_filename );

event_info_data = event_info.data;
event_info_labs = fcat.from( event_info.labels );

renamecat( event_info_labs, 'look_order', 'initiator' );
renamecat( event_info_labs, 'broke_order', 'terminator' );
renamecat( event_info_labs, 'looks_to', 'roi' );
rmcat( event_info_labs, {'session_name', 'unified_filename'} );

is_mut = find( event_info_labs, 'mutual' );

if ( ~isempty(event_info_labs) )
  addsetcat( event_info_labs, 'event_type', 'exclusive_event' );
  setcat( event_info_labs, 'event_type', 'mutual_event', is_mut );
end

replace( event_info_labs, 'look_order__m1', 'm1_initiated' );
replace( event_info_labs, 'look_order__m2', 'm2_initiated' );
replace( event_info_labs, 'look_order__simultaneous', 'simultaneous_start' );
replace( event_info_labs, 'look_order__NaN', '<initiator>' );

replace( event_info_labs, 'broke_order__m1', 'm1_terminated' );
replace( event_info_labs, 'broke_order__m2', 'm2_terminated' );
replace( event_info_labs, 'broke_order__simultaneous', 'simultaneous_stop' );
replace( event_info_labs, 'broke_order__NaN', '<terminator>' );

prune( event_info_labs );

event_key = containers.Map();
event_key('duration') = events_file.event_info_key('durations');
event_key('length') = events_file.event_info_key('lengths');
event_key('start_time') = events_file.event_info_key('times');

out_file = struct();
out_file.unified_filename = unified_filename;
out_file.events = event_info_data;
out_file.categories = columnize( getcats(event_info_labs) )';
out_file.labels = cellstr( event_info_labs );
out_file.event_key = event_key;

end