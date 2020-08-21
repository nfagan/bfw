function deg = px2deg(px, monitor_info)

if ( nargin < 2 )
  monitor_info = bfw_default_monitor_info();
end

h = monitor_info.height;
d = monitor_info.distance;
r = monitor_info.vertical_resolution;

deg_per_px = rad2deg( atan2(0.5*h, d)) / (0.5*r);
deg = px * deg_per_px;

end