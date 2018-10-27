function bounds = rect_mouth_inverted_eyes(calibration_data, key_map, padding_info, const, screen_rect)

%
%   EYES
%

eye_bounds = bfw.calibration.rect_eyes( calibration_data, key_map, padding_info, const, screen_rect );

eye_h = eye_bounds(4) - eye_bounds(2);

x0 = eye_bounds(1);
x1 = eye_bounds(3);
y0 = eye_bounds(4);
y1 = eye_bounds(4) + eye_h;

bounds = [ x0, y0, x1, y1 ];

end