function gaze_counts = load_gaze_counts_all_rois(varargin)

base_load_p = fullfile( bfw.dataroot(varargin{:}), 'analyses/spike_lda/reward_gaze_spikes' );

eye_non_eye_face_unmatched_obj = bfw_ct.load_eye_non_eye_face_nonsocial_object_gaze_counts( varargin{:} );
ns_obj_eyes_matched = shared_utils.io.fload( fullfile(base_load_p, '091119_nsobj_eyes_matched', 'gaze_counts.mat') );

%%

matched_label = 'nonsocial_object_eyes_nf_matched';
ns_obj_ind = find( ns_obj_eyes_matched.labels, matched_label );

dest_labels = eye_non_eye_face_unmatched_obj.labels';
src_labels = ns_obj_eyes_matched.labels;

dest_event_labels = eye_non_eye_face_unmatched_obj.event_labels';
src_event_labels = ns_obj_eyes_matched.event_labels;

append( dest_labels, src_labels, ns_obj_ind );
append( dest_event_labels, src_event_labels, ns_obj_ind );
collapse_ns_obj_rois( dest_event_labels, matched_label );

%%
gaze_counts = eye_non_eye_face_unmatched_obj;
gaze_counts.labels = dest_labels;
gaze_counts.event_labels = dest_event_labels;

gaze_counts.spikes = [ gaze_counts.spikes; ns_obj_eyes_matched.spikes(ns_obj_ind, :) ];
gaze_counts.events = [ gaze_counts.events; ns_obj_eyes_matched.events(ns_obj_ind, :) ];

end

function collapse_ns_obj_rois(labels, replace_with)

to_replace = {'left_nonsocial_object_eyes_nf_matched', 'right_nonsocial_object_eyes_nf_matched'};
replace( labels, to_replace, replace_with );

end