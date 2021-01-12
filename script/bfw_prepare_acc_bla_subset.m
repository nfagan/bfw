function [spike_data, event_data] = bfw_prepare_acc_bla_subset(spike_data, event_data)

spike_data = select_units( spike_data );
event_data = process_events( event_data );

end

function event_data = process_events(event_data)

pre_ns_obj_sessions = bfw.find_sessions_before_nonsocial_object_was_added( event_data.labels );
all_rois = combs( event_data.labels, 'roi' );
obj_rois = all_rois(cellfun(@(x) ~isempty(strfind(x, 'object')), all_rois));

remove_pre_ns_obj = find( event_data.labels, obj_rois, pre_ns_obj_sessions );
keep_events = setdiff( rowmask(event_data.labels), remove_pre_ns_obj );

keep_events = fcat.mask( event_data.labels, keep_events ...
  , @find, 'm1' ...
);

event_data = bfw.keep_events( event_data, keep_events, true );

keep_categories = { 'date', 'id_m1', 'id_m2', 'roi', 'looks_by' ...
  , 'run_number_str', 'session', 'task_type', 'unified_filename' };
rm_categories = setdiff( getcats(event_data.labels), keep_categories );
rmcat( event_data.labels, rm_categories );

all_labs = getlabs( event_data.labels );
for i = 1:numel(all_labs)
  if ( ~isempty(strfind(all_labs{i}, 'eyes_nf')) )
    replace_with = strrep( all_labs{i}, 'eyes_nf', 'eyes' );
    replace( event_data.labels, all_labs{i}, replace_with );
  end
end

event_data.labels = gather( event_data.labels );

event_keys = keys( event_data.event_key );
dest_keys = cell( numel(event_keys), 1 );

for i = 1:numel(event_keys)
  dest_keys{event_data.event_key(event_keys{i})} = event_keys{i};
end

event_data.event_key = dest_keys;

end

function spike_data = select_units(spike_data)

mask = findor( spike_data.labels, {'acc', 'bla'} );
labels = keep( spike_data.labels', mask );
spike_data.labels = gather( labels );
spike_data.spike_times = spike_data.spike_times(mask);

end