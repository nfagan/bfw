function rect = rect_nonsocial_object_eyes_nf_matched(nonsocial_obj_rect_func, varargin)

eye_rect = bfw.calibration.rect_eyes( varargin{:} );
nonsocial_object_rect = nonsocial_obj_rect_func( varargin{:} );

eye_area = rect_area( eye_rect );
object_area = rect_area( nonsocial_object_rect );

scale_factor = sqrt( eye_area/object_area );

center_obj = [ mean(nonsocial_object_rect([1, 3])), mean(nonsocial_object_rect([2, 4])) ];

new_obj_w = (nonsocial_object_rect(3) - nonsocial_object_rect(1)) * scale_factor;
new_obj_h = (nonsocial_object_rect(4) - nonsocial_object_rect(2)) * scale_factor;

x0 = center_obj(1) - new_obj_w/2;
x1 = center_obj(1) + new_obj_w/2;

y0 = center_obj(2) - new_obj_h/2;
y1 = center_obj(2) + new_obj_h/2;

rect = [ x0, y0, x1, y1 ];
% 
% %%
% 
% cla( gca );
% old_hs = bfw.plot_rect_as_lines( gca, nonsocial_object_rect );
% hold on;
% new_hs = bfw.plot_rect_as_lines( gca, rect );
% eye_hs = bfw.plot_rect_as_lines( gca, eye_rect );
% 
% set( eye_hs, 'color', 'r' );
% set( old_hs, 'color', 'g' );
% set( new_hs, 'color', 'b' );

end

function a = rect_area(r)

a = (r(3) - r(1)) * (r(4) - r(2));

end