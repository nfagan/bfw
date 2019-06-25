function bounds = rect_right_middle_nonsocial_object(calibration_data, key_map, padding_info, const, screen_rect)

face = bfw.calibration.rect_face( calibration_data, key_map, padding_info, const, screen_rect );

fw = face(3) - face(1);
fh = face(4) - face(2);

x_offset = screen_rect(1) + 1024*2 + 1024/2 - fw/2;
y_offset = screen_rect(2);

x0 = x_offset;
x1 = x_offset + fw;

y0 = y_offset;
y1 = y_offset + fh;

bounds = [ x0, y0, x1, y1 ];

end