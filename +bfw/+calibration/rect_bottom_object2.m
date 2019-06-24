function bounds = rect_bottom_object2(varargin)

object_bounds = bfw.calibration.rect_right_nonsocial_object( varargin{:} );

min_x = object_bounds(1);
min_y = object_bounds(2);
max_x = object_bounds(3);
max_y = object_bounds(4);

h = max_y - min_y;

bounds = [ min_x, min_y+h/2, max_x, max_y ];

end