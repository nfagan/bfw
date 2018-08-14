function eg_plot_fix_psth(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

conf = params.config;

selector = '08102018_position_1';

roi_file = bfw.load1( 'rois', selector, conf );
pos_file = bfw.load1( 'aligned', selector, conf );
evts_file = bfw.load1( 'events_per_day', selector, conf );

if ( evts_file.is_link )
  evts_file = bfw.loadlink( 'events_per_day', evts_file.data_file );
end

events = evts_file.event_info.data(:, evts_file.event_info_key('times'));
eventlabs = fcat.from( evts_file.event_info.labels );

%%

lb = -0.5;
la = 0;

colorfunc = @spring;

f = figure(1);
clf( f );

usedat = events;
uselabs = eventlabs';

rois = { 'eyes', 'face', 'outside1' };

shp = plotlabeled.get_subplot_shape( numel(rois) );
axs = gobjects( numel(rois), 1 );

for i = 1:numel(rois)  
  ax = subplot( shp(1), shp(2), i );
  
  rname = rois{i};

  pos = pos_file.m1.position;
  time = pos_file.m1.plex_time;
  rect = roi_file.m1.rects(rname);
  
  mask = fcat.mask( uselabs, @find, {roi_file.m1.unified_filename, rname} );

  bfw.plot_fix_psth( ax, time, pos, usedat(mask), lb, la, rect, colorfunc );
  
  title_str = strrep( strjoin({rname, selector}, ' | '), '_', ' ' );
  
  title( title_str );
  axs(i) = ax;
end

end

% shared_utils.plot.match_xlims( axs );
% shared_utils.plot.match_ylims( axs );

