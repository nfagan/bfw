function bounds = rect_top_object1(varargin)

object_bounds = bfw.calibration.rect_left_nonsocial_object( varargin{:} );

min_x = object_bounds(1);
min_y = object_bounds(2);
max_x = object_bounds(3);
max_y = object_bounds(4);

h = (max_y - min_y) / 2;

bounds = [ min_x, 0, max_x, h/2 ];

end