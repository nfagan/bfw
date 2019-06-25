function [x, y] = rect2verts(rect)

%   RECT2VERTS -- Convert rect to list of vertices.
%
%     [x, y] = bfw.rect2verts( rect ), for the 4-element vector `rect` 
%     returns 1x4 vectors `x` and `y` giving the vertices of the four 
%     corners of the rect.
%
%     See also patch

x0 = rect(1);
x1 = rect(3);
y0 = rect(2);
y1 = rect(4);

x = [ x0, x1, x1, x0 ];
y = [ y0, y0, y1, y1 ];

end