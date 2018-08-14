function bounds = rect_face(calibration_data, key_map, padding_info, const, screen_rect)

%
%   FACE
%

facetl = key_map( 'facetl' );
facetr = key_map( 'facetr' );
facebl = key_map( 'facebl' );
facebr = key_map( 'facebr' );

facetl_coord = bfw.calibration.get_coord( calibration_data, facetl );
facetr_coord = bfw.calibration.get_coord( calibration_data, facetr );
facebl_coord = bfw.calibration.get_coord( calibration_data, facebl );
facebr_coord = bfw.calibration.get_coord( calibration_data, facebr );

x0 = mean( [facetl_coord(1), facebl_coord(1)] );
x1 = mean( [facetr_coord(1), facebr_coord(1)] );

y0 = mean( [facetl_coord(2), facetr_coord(2)] );
y1 = mean( [facebl_coord(2), facebr_coord(2)] );

bounds = [ x0, y0, x1, y1 ];

end