un_file = '02052018';

monk = 'm1';

rois = bfw.load_one_intermediate( 'rois', un_file );
unified = bfw.load_one_intermediate( 'unified', un_file );

eyes = rois.(monk).rects('eyes');
face = rois.(monk).rects('face');

key_map = unified.(monk).far_plane_key_map;
calibration_data = unified.(monk).far_plane_calibration;

eyel = key_map( 'eyel' );
eyer = key_map( 'eyer' );
mouth = key_map( 'mouth' );

eyel_coord = bfw.calibration.get_coord( calibration_data, eyel );
eyer_coord = bfw.calibration.get_coord( calibration_data, eyer );
mouth_coord = bfw.calibration.get_coord( calibration_data, mouth );

x1f = face(1);
x2f = face(3);
y1f = face(2);
y2f = face(4);

x1e = eyes(1);
x2e = eyes(3);
y1e = eyes(2);
y2e = eyes(4);

figure(1); clf();

ax = gca;
set( ax, 'nextplot', 'add' );

marker_size = 2;

plot_shape = 'o';
plot_color_face = 'k';
plot_color_eyes = 'r';
plot_color_mouth = 'b';

plot_cmd_face = sprintf( '%s%s', plot_color_face, plot_shape );
plot_cmd_eyes = sprintf( '%s%s', plot_color_eyes, plot_shape );
plot_cmd_mouth = sprintf( '%s%s', plot_color_mouth, plot_shape );

plot_cmds_face = { plot_cmd_face, 'markersize', marker_size };
plot_cmds_eyes = { plot_cmd_eyes, 'markersize', marker_size };
plot_cmds_mouth = { plot_cmd_mouth, 'markersize', marker_size };

plot( mouth_coord(1), mouth_coord(2), plot_cmds_mouth{:} );

plot( x1f, y1f, plot_cmds_face{:} );
plot( x2f, y1f, plot_cmds_face{:} );
plot( x1f, y2f, plot_cmds_face{:} );
plot( x2f, y2f, plot_cmds_face{:} );

plot( x1e, y1e, plot_cmds_eyes{:} );
plot( x2e, y1e, plot_cmds_eyes{:} );
plot( x1e, y2e, plot_cmds_eyes{:} );
plot( x2e, y2e, plot_cmds_eyes{:} );

plot( eyel_coord(1), eyel_coord(2), plot_cmds_eyes{:} );
plot( eyer_coord(1), eyer_coord(2), plot_cmds_eyes{:} );
