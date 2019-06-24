function bounds = rect_bottom_mouth(varargin)

face_bounds = bfw.calibration.rect_face( varargin{:} );

min_x = face_bounds(1);
min_y = face_bounds(2);
max_x = face_bounds(3);
max_y = face_bounds(4);

h = (max_y - min_y) / 2;

bounds = [ min_x, h/2, max_x, h ];

end