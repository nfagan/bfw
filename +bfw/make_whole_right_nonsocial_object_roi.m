function [labels, transform_ind] = make_whole_right_nonsocial_object_roi(labels)

ind = find( labels, {'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched'} );
transform_ind = [rowmask(labels); ind];

assign_start = rows( labels ) + 1;
append( labels, labels, ind );
setcat( labels, 'roi', 'right_nonsocial_object_whole_face_matched', assign_start:rows(labels) );

end