pos_file =      bfw.load1( 'aligned_raw_samples/position', '0204' );
offsets_file =  bfw.load1( 'single_origin_offsets', pos_file.unified_filename );
roi_file =      bfw.load1( 'rois', pos_file.unified_filename );

% factor to make m1's origin (0, 0)
m1_offsets = offsets_file.m1;

% factor to make m2's *local* origin (0, 0)
m2_offsets = offsets_file.m2; 

% factor to make m2's origin the same as m1's
m2_to_m1 = offsets_file.m2_to_m1;

m1_corrected_position = pos_file.m1 + m1_offsets;
m2_corrected_position = pos_file.m2 + m2_offsets;
% Make m2's origin the same as m1's
m2_corrected_position(1, :) = m2_to_m1(1) - m2_corrected_position(1, :);

m1_eye_roi = roi_file.m1.rects('eyes');
m2_eye_roi = roi_file.m2.rects('eyes');

% m1_eye_roi is in format: [min_x, min_y, max_x, max_y]. We add the x
% offset -- m1_offsets(1) -- to the x coordinates, and the y offset --
% m1_offsets(2) -- to the y coordinates.
m1_eye_roi([1, 3]) = m1_eye_roi([1, 3]) + m1_offsets(1);

% m2_eye_roi is the same, but we subtract the result from 3072
m2_eye_roi([1, 3]) = m2_to_m1(1) - m2_eye_roi([1, 3]) + m2_offsets(1);

