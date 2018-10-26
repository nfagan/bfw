function bounds = rect_outside2(calibration_data, key_map, padding_info, const, screen_rect)

face_rect = bfw.calibration.rect_face( calibration_data, key_map, padding_info, const );

face_h = (face_rect(3) - face_rect(1))/2;
face_v = (face_rect(4) - face_rect(2))/2;

x1 = screen_rect(1);
x2 = screen_rect(3);

% before 0209 [0 0 3072 768] after [-1024 0 2048 768], should fix this
% later
if x2 == 3072
   x_center = (x2 - x1)/2;
else
   x_center = 0;
end  
ctr1 = [ x_center, 0 ];

% moving down to match nonsoc obj
ctr1 = [ x_center-face_h 0+face_v ];

bounds = [ctr1(1)-face_h ctr1(2)-face_v ctr1(1)+face_h ctr1(2)+face_v];

end