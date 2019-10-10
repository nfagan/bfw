function gaze_counts = load_eye_non_eye_face_nonsocial_object_gaze_counts(varargin)

base_load_p = fullfile( bfw.dataroot(varargin{:}), 'analyses/spike_lda/reward_gaze_spikes' );
gaze_counts = shared_utils.io.fload( fullfile(base_load_p, '092619_eyes_face_non_eye_face_nonsocial_object', 'gaze_counts.mat') );

% eye_non_eye_face = load( fullfile(base_load_p, '09062019_eyes_v_non_eyes_face/gaze_counts.mat') );
% ns_object = load( fullfile(base_load_p, 'revisit_09032019/gaze_counts.mat') );
% 
% ns_gaze_counts = ns_object.gaze_counts;
% gaze_counts = eye_non_eye_face.gaze_counts;
% 
% ns_ind = find( ns_gaze_counts.labels, 'nonsocial_object' );
% 
% gaze_counts.spikes = [ gaze_counts.spikes; ns_gaze_counts.spikes(ns_ind, :) ];
% append( gaze_counts.labels, ns_gaze_counts.labels, ns_ind );
% replace( gaze_counts.labels, 'face', 'face_non_eyes' );
% 
% gaze_counts.events = [ gaze_counts.events; ns_gaze_counts.events(ns_ind, :) ];
% gaze_counts.event_labels = append( gaze_counts.event_labels', ns_gaze_counts.event_labels, ns_ind );
% 
% assert_ispair( gaze_counts.spikes, gaze_counts.labels );
% assert_ispair( gaze_counts.events, gaze_counts.event_labels );

end