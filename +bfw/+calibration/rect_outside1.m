function bounds = rect_outside1(calibration_data, key_map, padding_info, const, screen_rect)

face_rect = bfw.calibration.rect_face( calibration_data, key_map, padding_info, const );

face_h = (face_rect(3) - face_rect(1))/2;
face_v = (face_rect(4) - face_rect(2))/2;

% the center of out face cluster 1 in the upper right corner of the monitor
% x1 = screen_rect(1);
x2 = screen_rect(3);

% x_center = (x2 - x1)/2 + x1;
x_center = x2;
ctr1 = [ x_center, 0 ];

bounds = [ctr1(1)-face_h ctr1(2)-face_v ctr1(1)+face_h ctr1(2)+face_v];

end