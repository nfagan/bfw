function bounds = rect_mouth(calibration_data, key_map, padding_info, const)

%
%   MOUTH
%

eyel = key_map( 'eyel' );
eyer = key_map( 'eyer' );

eyel_coord = bfw.calibration.get_coord( calibration_data, eyel );
eyer_coord = bfw.calibration.get_coord( calibration_data, eyer );

dist_eyes_px = eyer_coord(1) - eyel_coord(1);
dist_eyes_cm = const.INTER_EYE_DISTANCE_CM;
ratio = dist_eyes_px / dist_eyes_cm;

pad_x = padding_info.mouth.x;
pad_y = padding_info.mouth.y;

mouth_center = key_map( 'mouth' );

mouth_coord = bfw.calibration.get_coord( calibration_data, mouth_center );

if ( all(mouth_coord == 0) )
  mouth_coord = nan( size(mouth_coord) );
end

x0 = mouth_coord(1) - (ratio * pad_x);
x1 = mouth_coord(1) + (ratio * pad_x);

y0 = mouth_coord(2) - (ratio * pad_y);
y1 = mouth_coord(2) + (ratio * pad_y);

bounds = [ x0, y0, x1, y1 ];

end