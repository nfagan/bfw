function [labels, transform_ind] = make_whole_face_roi(labels)

ind = find( labels, {'eyes_nf', 'face'} );
transform_ind = [rowmask(labels); ind];

assign_start = rows( labels ) + 1;
append( labels, labels, ind );
setcat( labels, 'roi', 'whole_face', assign_start:rows(labels) );

end