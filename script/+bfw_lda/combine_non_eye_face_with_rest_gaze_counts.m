function rest = combine_non_eye_face_with_rest_gaze_counts(enef, rest)

face_ind_spikes = find( enef.labels, 'face' );
face_ind_events = find( enef.event_labels, 'face' );
assert( isequal(face_ind_spikes, face_ind_events), 'Spike & event indices for face mismatched.' );

out_spike_labels = append_setcat( rest.labels', enef.labels, face_ind_spikes );
out_event_labels = append_setcat( rest.event_labels', enef.event_labels, face_ind_spikes );

rest.spikes = [ rest.spikes; enef.spikes(face_ind_spikes, :) ];
rest.events = [ rest.events; enef.events(face_ind_spikes, :) ];

rest.labels = out_spike_labels;
rest.event_labels = out_event_labels;

assert_ispair( rest.spikes, rest.labels );
assert_ispair( rest.events, rest.event_labels );

end

function dest_labels = append_setcat(dest_labels, src_labels, src_mask)

init_rows = rows( dest_labels );
append( dest_labels, src_labels, src_mask );
new_num_rows = rows( dest_labels );
setcat( dest_labels, 'roi', 'face_non_eyes', (init_rows+1):new_num_rows );

end