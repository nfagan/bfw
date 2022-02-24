function map = bfw_make_color_map(c0, c1, num_points)

% https://www.mathworks.com/matlabcentral/answers/265914-how-to-make-my-own-custom-colormap

validateattributes( c0, {'uint8'}, {'numel', 3}, mfilename, 'color0' );
validateattributes( c1, {'uint8'}, {'numel', 3}, mfilename, 'color1' );

c0 = double( c0 ) / 255;
c1 = double( c1 ) / 255;

vec = [100; 0];
map = interp1( vec, [c0(:)'; c1(:)'], linspace(100, 0, num_points), 'pchip' );

end