function hs = plot_rect_as_lines(ax, rect)

x0 = rect(1);
x1 = rect(3);
y0 = rect(2);
y1 = rect(4);

hs = gobjects( 4, 1 );

hs(1) = plot( ax, [x0, x1], [y0, y0] );
hold on;
hs(2) = plot( ax, [x1, x1], [y0, y1] );
hs(3) = plot( ax, [x0, x1], [y1, y1] );
hs(4) = plot( ax, [x0, x0], [y0, y1] );

end