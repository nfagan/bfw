function bfw_plot_event_timeline(events, event_key, labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.each = { 'looks_by', 'roi' };
defaults.panels = {};
defaults.line_width = 2;
defaults.box_height = 2;
defaults.color_func = @jet;
defaults.x_lims = [];
defaults.y_lims = [];
params = bfw.parsestruct( defaults, varargin );

assert_ispair( events, labels );

all_starts = events(:, event_key('start_time'));
all_durs = events(:, event_key('duration'));

mask = get_base_mask( all_starts, all_durs, labels, params.mask_func );

f = figure( 1 );
clf( f );

panel_I = findall_or_one( labels, params.panels, mask );
shape = plotlabeled.get_subplot_shape( numel(panel_I) );

for i = 1:numel(panel_I)

ax = subplot( shape(1), shape(2), i );
cla( ax );

plot_one_panel( ax, all_starts, all_durs, labels, panel_I{i}, params );

end

if ( params.do_save )
  maybe_save_fig( f, prune(labels(mask)), params );
end

end

function maybe_save_fig(f, save_labs, params)

save_p = get_save_path( params );
spec = csunion( params.each, params.panels );
shared_utils.plot.fullscreen( f );
dsp3.req_savefig( f, save_p, save_labs, spec, params.prefix );

end

function plot_one_panel(ax, all_starts, all_durs, labels, mask, params)

[each_I, each_C] = findall( labels, params.each, mask );

shared_utils.plot.hold( ax, 'on' );
hs = cell( size(each_I) );
colors = params.color_func( numel(each_I) );

for i = 1:numel(each_I)
  starts = all_starts(each_I{i});
  durs = all_durs(each_I{i});
  tmp_hs = gobjects( numel(starts), 1 );
  
  for j = 1:numel(starts)
    x0 = starts(j);
    y0 = -params.box_height/2;
    w = durs(j);
    h = params.box_height;
    tmp_hs(j) = rectangle( ax, 'position', [x0, y0, w, h] );
    set( tmp_hs(j), 'FaceColor', colors(i, :) );
  end
  
  hs{i} = tmp_hs;
end

lims = params.y_lims;

if ( isempty(lims) )
  lims = [-params.box_height, params.box_height];
end

leg_labels = fcat.strjoin( each_C, ' | ' );
leg_labels = eachcell( @(x) strrep(x, '_', ' '), leg_labels );

dummy_lines_to_add_legend( ax, lims, colors, leg_labels );
shared_utils.plot.set_ylims( ax, lims );
shared_utils.plot.set_xlims( ax, params.x_lims );

panel_labs = strjoin( fcat.strjoin(combs(labels, params.panels, mask), ' | '), ' ' );
panel_labs = strrep( panel_labs, '_', ' ' );
title( ax, panel_labs );

xlabel( ax, 'Time (s) from session start' );

end

function dummy_lines_to_add_legend(ax, lims, colors, leg_labels)

assert( rows(colors) == numel(leg_labels) ...
  , 'Size mismatch between legend entries and colors.' );

hs = gobjects( rows(colors), 1 );

for i = 1:rows(colors)
  hs(i) = plot( ax, get(ax, 'xlim'), repmat(max(lims)+1, 1, 2), 'linewidth', 2 );
  set( hs(i), 'color', colors(i, :) );
end

legend( hs, leg_labels );

end

function mask = get_base_mask(starts, durs, labels, mask_func)

base_mask = intersect( find(~isnan(starts)), find(~isnan(durs)) );
mask = mask_func( labels, base_mask );

end

function save_p = get_save_path(params)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'behavior', dsp3.datedir ...
  , 'event_timeline', params.base_subdir );

end