function bounds = rect_mouth_from_eyes(calibration_data, key_map, padding_info, const, screen_rect)

%
%   EYES
%

eyel = key_map( 'eyel' );
eyer = key_map( 'eyer' );

eyel_coord = bfw.calibration.get_coord( calibration_data, eyel );
eyer_coord = bfw.calibration.get_coord( calibration_data, eyer );

eye_y = mean( [eyel_coord(2), eyer_coord(2)] );
eye_center_x = mean( [eyel_coord(1), eyer_coord(1)] );

dist_eyes_px = eyer_coord(1) - eyel_coord(1);
dist_eyes_cm = const.INTER_EYE_DISTANCE_CM;
ratio = dist_eyes_px / dist_eyes_cm;

mouth_center_y = eye_y + (ratio * const.MOUTH_TO_EYE_CENTER_CM);
mouth_center_x = eye_center_x;

mouthl_px = mouth_center_x - (padding_info.mouth.x * ratio);
mouthr_px = mouth_center_x + (padding_info.mouth.x * ratio);

mouthb_px = mouth_center_y - (padding_info.mouth.y * ratio);
moutht_px = mouth_center_y + (padding_info.mouth.y * ratio);

bounds = [ mouthl_px, mouthb_px, mouthr_px, moutht_px ];

end