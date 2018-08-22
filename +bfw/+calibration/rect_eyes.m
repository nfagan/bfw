function bounds = rect_eyes(calibration_data, key_map, padding_info, const, screen_rect)

%
%   EYES
%

eyel = key_map( 'eyel' );
eyer = key_map( 'eyer' );

eyel_coord = bfw.calibration.get_coord( calibration_data, eyel );
eyer_coord = bfw.calibration.get_coord( calibration_data, eyer );

eye_y = mean( [eyel_coord(2), eyer_coord(2)] );

dist_eyes_px = eyer_coord(1) - eyel_coord(1);
dist_eyes_cm = const.INTER_EYE_DISTANCE_CM;
ratio = dist_eyes_px / dist_eyes_cm;

eyel_px = eyel_coord(1) - (padding_info.eyes.x * ratio);
eyer_px = eyer_coord(1) + (padding_info.eyes.x * ratio);
eyeb_px = eye_y - (padding_info.eyes.y * ratio);
eyet_px = eye_y + (padding_info.eyes.y * ratio);

bounds = [ eyel_px, eyeb_px, eyer_px, eyet_px ];

% bounds = bounds + [-15, -15, 15, 15];

end