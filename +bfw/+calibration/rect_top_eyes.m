function bounds = rect_top_eyes(varargin)

face_bounds = bfw.calibration.rect_face( varargin{:} );

min_x = face_bounds(1);
min_y = face_bounds(2);
max_x = face_bounds(3);
max_y = face_bounds(4);

h = max_y - min_y;

bounds = [ min_x, min_y, max_x, min_y+h/2 ];

end