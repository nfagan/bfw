function map = get_calibration_key_roi_map()

keys = { 'eyel', 'eyer', 'facebl', 'facetl', 'facebr', 'facetr', 'mouth' };
values = { 2, 6, 5, 3, 7, 4, 1 };

map = containers.Map( keys, values );

end