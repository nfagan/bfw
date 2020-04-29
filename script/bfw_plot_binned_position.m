function bfw_plot_binned_position(counts, count_labels, spatial_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.zscore_collapse = false;
defaults.mask_func = @(l, m) m;
defaults.use_custom_rois = false;
defaults.custom_rois = [];
defaults.invert_y = false;
defaults.c_lims = [];
defaults.to_degrees = false;
defaults.square_axes = false;
defaults.smooth_func = [];
defaults.monitor_info = bfw_default_monitor_info;
defaults.color_map = 'jet';

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

save_p = fullfile( bfw.dataroot(conf), 'plots', 'binned_position_psth', 'lower-res', dsp3.datedir );

use_labels = count_labels';
use_data = counts;

x_edges = spatial_outs.x_edges(1, :);
y_edges = spatial_outs.y_edges(1, :);

pl = plotlabeled.make_spectrogram( x_edges, y_edges );
pl.fig = figure(1);
pl.add_smoothing = true;
pl.invert_y = ~params.invert_y;

if ( ~isempty(params.smooth_func) )
  pl.smooth_func = params.smooth_func;
end

plt_mask = get_base_mask( use_labels, params.mask_func );
[use_data, use_labels, plt_mask] = handle_unit_collapsing( use_data, use_labels, plt_mask, params );

figs_each = { 'unit_uuid', 'session', 'region' };
fig_I = findall_or_one( use_labels, figs_each, plt_mask );

possible_rois = combs( spatial_outs.labels, 'roi' );

for idx = 1:numel(fig_I)
  fig_mask = fig_I{idx};

  plt_counts = use_data(fig_mask, :, :);  
  plt_labels = use_labels(fig_mask);
  
  %%
  
  plot_new( plt_counts, plt_labels, x_edges, y_edges, params );
  
  %%
  
%   axs = plot_original( pl, plt_counts, plt_labels, x_edges, y_edges, params );
%   
%   if ( params.use_custom_rois || ~params.zscore_collapse )
%     add_rois( axs, spatial_outs, x_edges, y_edges, use_labels, possible_rois ...
%       , fig_mask, params );
%   end
  
  if ( params.do_save )
    img_formats = { 'epsc', 'png', 'fig', 'svg' };
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, prune(plt_labels), figs_each, '', img_formats );
  end
end

end

function plot_new(plt_counts, plt_labels, x_edges, y_edges, params)

pcats = { 'unit_uuid','roi','region' };

[plt_I, plt_C] = findall( plt_labels, pcats );
shape = plotlabeled.get_subplot_shape( numel(plt_I) );
axs = gobjects( numel(plt_I), 1 );

for i = 1:numel(plt_I)
  ax = subplot( shape(1), shape(2), i );
  axs(i) = ax;

  plt_roi_label = plt_C{2, i};
  tmp = bfw.row_nanmean( plt_counts, plt_I );

  tmp_dat = squeeze( tmp(i, :, :) );
  tmp_dat = flipud( tmp_dat );
  if ( ~isempty(params.smooth_func) )
    tmp_dat = params.smooth_func( tmp_dat );
  end
  
  sc_h = imagesc( ax, tmp_dat );
  set( ax, 'ydir', 'normal' );

  span = @(x) max(x) - min(x);

  xlims = get( ax, 'xlim' );
  ylims = get( ax, 'ylim' );
  xedge = linspace( xlims(1), xlims(2), numel(x_edges) );
  yedge = linspace( ylims(1), ylims(2), numel(y_edges) );
  
  plt_roi = params.custom_rois(plt_roi_label);
  roi_x0 = plt_roi(1) * span( xedge ) + min( xedge );
  roi_y0 = plt_roi(2) * span( yedge ) + min( yedge );
  roi_w = shared_utils.rect.width( plt_roi ) * span( xedge );
  roi_h = shared_utils.rect.height( plt_roi ) * span( yedge );
  trans_rect = [ roi_x0, roi_y0, roi_w, roi_h ];

%   rel_roi_x = (plt_roi([1, 3]) - min(x_edges)) / span(x_edges);
%   rel_roi_y = (plt_roi([2, 4]) - min(y_edges)) / span(y_edges);
%   rel_roi_x0 = rel_roi_x(1);
%   rel_roi_w = diff(rel_roi_x);
%   rel_roi_y0 = rel_roi_y(1);
%   rel_roi_h = diff(rel_roi_y);
% 
%   trans_rect = [rel_roi_x0, rel_roi_y0, rel_roi_w, rel_roi_h];
%   trans_rect([1, 3]) = trans_rect([1, 3]) * span(xedge) + min(xedge);
%   trans_rect([2, 4]) = trans_rect([2, 4]) * span(yedge) + min(yedge);
  
  if ( params.to_degrees )
    plt_x_edges = to_degrees( x_edges, params );
    plt_y_edges = to_degrees( y_edges, params );
  else
    plt_x_edges = x_edges;
    plt_y_edges = y_edges;
  end

  rectangle( ax, 'position', trans_rect );
  shared_utils.plot.tseries_xticks( ax, round(plt_x_edges), 10 );
  shared_utils.plot.fseries_yticks( ax, round(plt_y_edges), 10 );
  
  title_str = fcat.strjoin( plt_C(:, i) , ' | ' );
  title( ax, strrep(title_str, '_', ' ') );
  
  if ( params.square_axes )
    axis( ax, 'square' );
  end
  
  colorbar;
  colormap( params.color_map );
  
  shared_utils.plot.set_clims( ax, params.c_lims );
end

end

function axs = plot_original(pl, plt_counts, plt_labels, x_edges, y_edges, params)

plt_x_edges = x_edges;
plt_y_edges = flip( y_edges );

if ( params.invert_y )
  plt_y_edges = flip( y_edges );
end

plt_cats = { 'unit_uuid', 'roi', 'region' };
axs = pl.imagesc( plt_counts, plt_labels, plt_cats );

if ( params.to_degrees )
  plt_x_edges = to_degrees( plt_x_edges, params );
  plt_y_edges = to_degrees( plt_y_edges, params );
end

shared_utils.plot.tseries_xticks( axs, round(plt_x_edges), 10 );
shared_utils.plot.fseries_yticks( axs, round(plt_y_edges), 10 );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, find(x_edges == 0) );
shared_utils.plot.add_horizontal_lines( axs, find(y_edges == 0) );
shared_utils.plot.set_clims( axs, params.c_lims );

if ( params.square_axes )
  arrayfun( @(x) axis(x, 'square'), axs );
end
 
end

function add_rois(axs, spatial_outs, x_edges, y_edges, use_labels, possible_rois, fig_mask, params)

for i = 1:numel(axs)
  ax = axs(i);
  title_labels = strrep( strsplit(get(get(ax, 'title'), 'string'), ' | '), ' ', '_' );
  roi = title_labels(ismember(title_labels, possible_rois));

  if ( params.use_custom_rois )
    assert( ~isempty(params.custom_rois), 'No custom rois were given.' );
    assert( isa(params.custom_rois, 'containers.Map') && ...
      isKey(params.custom_rois, char(roi)), 'No custom roi matched: "%s".', char(roi) );
    rect = params.custom_rois(char(roi));
    
  else
    roi_ind = fcat.mask( spatial_outs.labels ...
      , @find, roi ...
      , @find, combs(use_labels, 'session', fig_mask) ...
    );

    rect = unique( spatial_outs.relative_rois(roi_ind, :), 'rows' );
    assert( rows(rect) == 1 );
  end

  relative_x = (rect([1, 3]) - min(x_edges)) / (max(x_edges) - min(x_edges));
  relative_y = 1 - (rect([2, 4]) - min(y_edges)) / (max(y_edges) - min(y_edges));

  xs = round( relative_x * numel(get(ax, 'xtick')) );
  ys = round( relative_y * numel(get(ax, 'ytick')) );

  rect = [ xs(1), ys(1), xs(2), ys(2) ];

  h = bfw.plot_rect_as_lines( ax, rect );
  set( h, 'color', zeros(3, 1) );
  set( h, 'linewidth', 2 );
end

end

function mask = get_base_mask(labels, mask_func)

mask = mask_func( labels, rowmask(labels) );

end

function [data, labels, mask] = zscore_collapse(data, labels, mask)

zscore_each = { 'unit_uuid', 'session', 'region', 'roi' };
mean_each = { 'region', 'roi' };

z_I = findall( labels, zscore_each, mask );

for i = 1:numel(z_I)
  subset = data(z_I{i}, :, :);
  data(z_I{i}, :, :) = (subset - nanmean(subset(:))) ./ nanstd( subset(:) );
end

[labels, I] = keepeach( labels, mean_each, mask );
data = bfw.row_nanmean( data, I );

to_collapse = setdiff( zscore_each, mean_each );
collapsecat( labels, to_collapse );
mask = rowmask( labels );

end

function [data, labels, mask] = zscore_collapse2(data, labels, mask)

zscore_each = { 'unit_uuid', 'session', 'region' };
z_I = findall( labels, zscore_each, mask );

for i = 1:numel(z_I)
  ind = z_I{i};
  tot = columnize( data(ind, :, :) );
  mu = nanmean( tot );
  dev = nanstd( tot );
  data(ind, :, :) = (data(ind, :, :) - mu) / dev;
end

collapsecat( labels, {'unit_uuid', 'session'} );

end

function [data, labels, mask] = handle_unit_collapsing(data, labels, mask, params)

if ( params.zscore_collapse )
%   [data, labels, mask] = zscore_collapse( data, labels, mask );
  [data, labels, mask] = zscore_collapse2( data, labels, mask );
end

end

function deg = to_degrees(px, params)

info = params.monitor_info;
deg = hwwa.px2deg( px, info.height, info.distance, info.vertical_resolution );

end