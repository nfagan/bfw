function bounds = rect_padded_face_medium(calibration_data, key_map, padding_info, const, screen_rect, dist)

med_dist = dist * (2/3);

bounds = bfw.calibration.rect_padded_face_impl( calibration_data, key_map, padding_info, const, screen_rect, med_dist );

end