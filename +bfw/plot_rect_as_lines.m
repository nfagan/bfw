function hs = plot_rect_as_lines(ax, rect)

%   PLOT_RECT_AS_LINES -- Plot outline of rect.
%
%     bfw.plot_rect_as_lines( ax, rect ); plots an outline of `rect`, a
%     4-element vector specifying min_x, min_y, max_x, and max_y
%     coordinates, into `ax`, an axes object.
%
%     hs = bfw.plot_rect_as_lines(...) returns a 4x1 array of handles to
%     the plotted lines.
%
%     See also bfw.calibration.rect_eyes

x0 = rect(1);
x1 = rect(3);
y0 = rect(2);
y1 = rect(4);

hs = gobjects( 4, 1 );

span_x = [ x0, x1 ];
span_y = [ y0, y1 ];
min_x = [ x0, x0 ];
max_x = [ x1, x1 ];
min_y = [ y0, y0 ];
max_y = [ y1, y1 ];

hold( ax, 'on' );

hs(1) = plot( ax, span_x, min_y );
hs(2) = plot( ax, max_x, span_y );
hs(3) = plot( ax, span_x, max_y );
hs(4) = plot( ax, min_x, span_y );

end