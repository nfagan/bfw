function bounds = rect_padded_face_impl(calibration_data, key_map, padding_info, const, screen_rect, dist)

face_bounds = bfw.calibration.rect_face( calibration_data, key_map, padding_info, const, screen_rect );

w = face_bounds(3) - face_bounds(1);
h = face_bounds(4) - face_bounds(2);

cx = face_bounds(1) + (w/2);
cy = face_bounds(2) + (h/2);

x0 = cx - dist;
x1 = cx + dist;
y0 = cy - dist;
y1 = cy + dist;

bounds = [ x0, y0, x1, y1 ];

end