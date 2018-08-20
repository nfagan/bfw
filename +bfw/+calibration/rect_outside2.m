function bounds = rect_outside2(calibration_data, key_map, padding_info, const)

face_rect = bfw.calibration.rect_face( calibration_data, key_map, padding_info, const );

face_h = (face_rect(3) - face_rect(1))/2;
face_v = (face_rect(4) - face_rect(2))/2;

ctr1 = [1536 0];
bounds = [ctr1(1)-face_h ctr1(2)-face_v ctr1(1)+face_h ctr1(2)+face_v];

end