function bounds = rect_padded_face_small(calibration_data, key_map, padding_info, const, screen_rect, dist)

small_dist = dist / 3;

bounds = bfw.calibration.rect_padded_face_impl( calibration_data, key_map, padding_info, const, screen_rect, small_dist );

end