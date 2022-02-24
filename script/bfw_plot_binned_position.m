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
defaults.per_unit = false;
defaults.plot_heatmap = true;
defaults.normalize_xy_roi_info_to_bla = false;
defaults.use_roi_center_for_dispersion = false;
defaults.dispersion_x_deg_limits = [-inf, inf];
defaults.dispersion_y_deg_limits = [-inf, inf];
defaults.use_raw_counts_for_dispersion = true;
defaults.zero_one_normalize = false;
defaults.dispersion_data = [];
defaults.collapse_units_in_dispersion_stats = false;
defaults.per_dispersion_quantile = false;
defaults.violin_gcats = { 'region' };
defaults.violin_pcats = { 'roi' };

params = bfw.parsestruct( defaults, varargin );

use_labels = count_labels';
use_data = counts;
dispersion_data = use_data;

if ( ~isempty(params.dispersion_data) )
  assert( isequal(size(params.dispersion_data), size(use_data)) ...
    , 'dispersion data must match size of spike data.' );
  dispersion_data = params.dispersion_data;
  params.use_dispersion_data = true;
else
  params.use_dispersion_data = false;
end

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
raw_data = use_data;
[use_data, use_labels, plt_mask] = handle_unit_collapsing( use_data, use_labels, plt_mask, params );

if ( params.plot_heatmap )
  figs_each = { 'unit_uuid', 'session', 'region' };
else
  figs_each = {};
end

fig_I = findall_or_one( use_labels, figs_each, plt_mask );

possible_rois = combs( spatial_outs.labels, 'roi' );

for idx = 1:numel(fig_I)
  fig_mask = fig_I{idx};

  plt_counts = use_data(fig_mask, :, :);  
  plt_labels = use_labels(fig_mask);
  plt_raw_counts = raw_data(fig_mask, :, :);
  plt_dispersion_data = dispersion_data(fig_mask, :, :);
  
  %%
  
  if ( params.plot_heatmap )
    plot_heatmap( plt_counts, plt_labels', x_edges, y_edges, params );
  else
%     plot_xy_roi_info( plt_counts, plt_raw_counts, plt_dispersion_data ...
%       , plt_labels', x_edges, y_edges, params );
    plot_roi_stats( plt_counts, plt_labels', x_edges, y_edges, params );
%     plot_dispersion_stats( plt_dispersion_data, plt_labels' ...
%       , to_degrees(x_edges, params), to_degrees(y_edges, params), params );
  end
end

end

function roi_means = get_roi_means(counts, labels, x_edges, y_edges, params)

[roi_I, roi_C] = findall( labels, 'roi' );

roi_means = nan( rows(counts), 1 );

for i = 1:numel(roi_I)
  frac_roi = params.custom_rois(roi_C{i});
  roi_x = min( x_edges ) + (max(x_edges) - min(x_edges)) .* frac_roi([1, 3]);
  roi_y = min( y_edges ) + (max(y_edges) - min(y_edges)) .* frac_roi([2, 4]);
  
  ib_x = x_edges >= roi_x(1) & x_edges < roi_x(2);
  ib_y = y_edges >= roi_y(1) & y_edges < roi_y(2);
  
  % Extract slab of `counts` within the roi bounds.
  sub_region = counts(roi_I{i}, ib_x, ib_y);
  % Average across x and y dimensions, leaving trials intact.
  mean_region = nanmean( nanmean(sub_region, 2), 3 );
  
  roi_means(roi_I{i}) = mean_region;
end

end

function [counts, x, y] = counts_within_deg_limits(counts, x, y, x_lims, y_lims)

within_x = x >= x_lims(1) & x <= x_lims(2);
within_y = y >= y_lims(1) & y <= y_lims(2);

counts = counts(:, within_y, within_x);
x = x(within_x);
y = y(within_y);

end

function plot_xy_roi_info(counts, raw_counts, dispersion_data, labels, x_edges, y_edges, params)

x_deg_edges = to_degrees( x_edges, params );
y_deg_edges = to_degrees( y_edges, params );

roi_means = get_roi_means( counts, labels', x_edges, y_edges, params );

if ( params.use_dispersion_data )
  disp_counts = dispersion_data;
  
elseif ( params.use_raw_counts_for_dispersion )
  disp_counts = raw_counts;
  
else
  disp_counts = counts;
end

[disp_counts, x_deg_edges, y_deg_edges] = ...
  counts_within_deg_limits( disp_counts, x_deg_edges, y_deg_edges ...
  , params.dispersion_x_deg_limits, params.dispersion_y_deg_limits );

dispersions = get_dispersions( disp_counts, labels, x_deg_edges, y_deg_edges ...
  , params.use_roi_center_for_dispersion );

if ( params.per_dispersion_quantile )
  disp_quantiles = dsp3.quantiles_each( dispersions, labels', 2, {'region', 'roi'}, {} );
  quant_labels = arrayfun( @(x) sprintf('dispersion-quantile-%d', x), disp_quantiles, 'un', 0 );
  addsetcat( labels, 'dispersion-quantile', quant_labels );
end

assert( isequal(size(roi_means), size(dispersions)) && isvector(roi_means) );

%%
pcats = { 'roi' };
gcats = { 'region' };

if ( params.per_dispersion_quantile )
  pcats = union( pcats, {'dispersion-quantile'} );
end

[p_I, p_C] = findall( labels, pcats );
axs = gobjects( numel(p_I), 1 );
shp = plotlabeled.get_subplot_shape( numel(p_I) );

summary_func = @plotlabeled.nanmean;
err_func = @plotlabeled.nansem;
color_func = @hsv;

add_points = false;
normalize_to_bla = params.normalize_xy_roi_info_to_bla;

for i = 1:numel(p_I)
  p_ind = p_I{i};
  ax = subplot( shp(1), shp(2), i );
  hold( ax, 'off' );
  axs(i) = ax;
  
  [g_I, g_C] = findall( labels, gcats, p_ind );
  colors = color_func( numel(g_I) );
  h_leg = gobjects( numel(g_I), 1 );
  
  if ( normalize_to_bla )
    is_bla = ismember( g_C, {'bla'} );
    assert( nnz(is_bla) == 1 );
    bla_ind = g_I{is_bla};
  end
  
  for j = 1:numel(g_I)
    g_ind = g_I{j};
    x = dispersions(g_ind);
    y = roi_means(g_ind);
    
    cx = summary_func( x );
    cy = summary_func( y );
    ex = err_func( x );
    ey = err_func( y );
    
    if ( normalize_to_bla )
      cx_bla = summary_func( dispersions(bla_ind) );
      cy_bla = summary_func( roi_means(bla_ind) );
      
      cx = cx / cx_bla;
      cy = cy / cy_bla;
    end
    
    h = plot( ax, cx, cy, 'k*' );
    hold( ax, 'on' );
    set( h, 'color', colors(j, :) );
    
    if ( ~normalize_to_bla )
      x0 = cx - ex * 0.5;
      x1 = cx + ex * 0.5;
      h_ex = plot( ax, [x0, x1], [cy, cy] );
      set( h_ex, 'color', colors(j, :) );

      y0 = cy - ey * 0.5;
      y1 = cy + ey * 0.5;
      h_ey = plot( ax, [cx, cx], [y0, y1] );
      set( h_ey, 'color', colors(j, :) );
    end
    
    h_leg(j) = h;
    
    if ( add_points )
      hold( ax, 'on' );
      h_scatter = scatter( ax, x, y, 0.2 );
      set( h_scatter, 'markeredgecolor', colors(j, :) );
    end
  end
  
  if ( i == 1 )
    legend( h_leg, fcat.strjoin(g_C, ' | ') );
  end
  
  title( ax, strrep(strjoin(p_C(:, i), ' | '), '_', ' ') );
end

%%
shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

if ( normalize_to_bla )
  shared_utils.plot.set_xlims( axs, [0.9, 1.1] );
  shared_utils.plot.set_ylims( axs, [-6, 10] );
  
  xlabel( axs(1), 'Dispersion of spiking activity normalized to BLA' );
  ylabel( axs(1), 'Average z-scored spiking activity normalized to BLA' );  
else
  xlabel( axs(1), 'Dispersion (deg)' );
  ylabel( axs(1), 'Average z-scored spiking activity' );
end
%%
if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( base_save_dir(params.config), 'xy-stats' );
  dsp3.req_savefig( gcf, save_p, prune(labels), [pcats, gcats] );
end

end

function plot_roi_stats(counts, labels, x_edges, y_edges, params)

%%

roi_means = get_roi_means( counts, labels', x_edges, y_edges, params );

%%
% 
% pl = plotlabeled.make_common();
% axs = pl.boxplot( roi_means, labels, 'region', 'roi' );

%%

plot_type = 'violin';

if ( strcmp(plot_type, 'violin') )
  pl = plotlabeled.make_common();
  
  if ( ismember({'region'}, params.violin_gcats) )
    pl.group_order = {'bla', 'ofc', 'acc', 'dmpfc'};
  elseif ( ismember({'region'}, params.violin_pcats) )
    pl.panel_order = {'bla', 'ofc', 'acc', 'dmpfc'};
  end
  axs = pl.violinalt( roi_means, labels, params.violin_gcats, params.violin_pcats );
  
elseif ( strcmp(plot_type, 'bar') )
  pl = plotlabeled.make_common();
  pl.add_points = true;
  pl.points_are = { 'roi' };
  line_width = 0.1;

  axs = pl.bar( roi_means, labels, 'region', 'roi', {} );
  ylabel( axs(1), 'Mean z-scored spike count' );

  for i = 1:numel(axs)
    hs = findobj( axs(i), 'type', 'bar' );
    line_hs = findobj( axs(i), 'type', 'errorbar' );

    xs = cat_expanded( 2, arrayfun(@(x) x.XEndPoints, hs, 'un', 0) );
    ys = cat_expanded( 2, arrayfun(@(x) x.YEndPoints, hs, 'un', 0) );

    delete( hs );
    delete( line_hs );

    hold( axs(i), 'on' );
    new_line_hs = gobjects( size(xs) );

    for j = 1:numel(xs)
      x0 = xs(j) - line_width * 0.5;
      x1 = xs(j) + line_width * 0.5;

      new_line_hs(j) = plot( axs(i), [x0, x1], [ys(j), ys(j)] );
      new_line_hs(j).Annotation.LegendInformation.IconDisplayStyle = 'off';
    end

    set( new_line_hs, 'color', 'k' );
  end
  
else
  error( 'Unrecognized plot type "%s".', plot_type );
end

%%

anova_factors = { 'region', 'roi' };
% anova_outs = dsp3.anovan( roi_means, labels', {}, anova_factors ...
%   , 'remove_nonsignificant_comparisons', true ...
% );

anova_outs = dsp3.anovan2( roi_means, labels', {}, anova_factors );

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( base_save_dir(params.config), 'roi-stats' );
  dsp3.req_savefig( gcf, save_p, prune(labels), anova_factors );
  
  stat_p = fullfile( save_p, 'stats' );
  dsp3.save_anova_outputs( anova_outs, stat_p, anova_factors );
end
end

function dispersions = get_dispersions(counts, labels, x_edges, y_edges, use_roi_center)

stats_each = { 'unit_uuid', 'roi', 'region' };
stat_I = findall_or_one( labels, stats_each );

% max_val = max( counts(:) );
% min_val = min( counts(:) );
% counts = (counts - min_val) ./ (max_val - min_val);

[gy, gx] = ndgrid( x_edges, y_edges );
dispersions = nan( rows(counts), 1 );

for i = 1:numel(stat_I)
  stat_ind = stat_I{i};
  cts = rowref( counts, stat_ind );
  
  for j = 1:rows(cts)
    arr = squeeze( cts(j, :, :) );
    wx = arr .* gx;
    wy = arr .* gy;
    
%     mu_x = nanmean( wx(:) );
%     mu_y = nanmean( wy(:) );
    
    mu_x = sum( wx(:) ) / sum( arr(:) );
    mu_y = sum( wy(:) ) / sum( arr(:) );
    
    len = zeros( numel(wx), 1 );
    
    for k = 1:numel(gx)
      if ( use_roi_center )
        d = [ gx(k), gy(k) ];
      else
        d = [ gx(k), gy(k) ] - [ mu_x, mu_y ];
      end
      
      len(k) = sqrt( dot(d, d) ) * arr(k);
    end
    
    dispersions(stat_ind(j)) = sum( len ) / sum( arr(:) );
    
%     for k = 1:numel(wx)
%       d = [ wx(k), wy(k) ] - [ mu_x, mu_y ];
%       len(k) = sqrt( dot(d, d) );
%     end
%     
%     dispersions(stat_ind(j)) = nanmean( len );
  end
end

end

function plot_dispersion_stats(counts, labels, x_edges, y_edges, params)

dispersions = get_dispersions( counts, labels, x_edges, y_edges ...
  , params.use_roi_center_for_dispersion );

if ( params.per_dispersion_quantile )
  disp_quantiles = dsp3.quantiles_each( dispersions, labels', 2, {'region', 'roi'}, {} );
  quant_labels = arrayfun( @(x) sprintf('dispersion-quantile-%d', x), disp_quantiles, 'un', 0 );
  addsetcat( labels, 'dispersion-quantile', quant_labels );
else
  addcat( labels, 'dispersion-quantile' );
end

collapse_units = params.collapse_units_in_dispersion_stats;

if ( collapse_units )
  [labels, collapsed_I] = keepeach( labels', {'session', 'roi', 'dispersion-quantile'} );
  dispersions = bfw.row_nanmean( dispersions, collapsed_I );
  collapsecat( labels, 'region' );
end

%%

pl = plotlabeled.make_common();
% axs = pl.boxplot( dispersions, labels, 'region', {'roi', 'dispersion-quantile'} );
axs = pl.violinalt( dispersions, labels, 'region', {'roi', 'dispersion-quantile'} );

%%

anova_factors = { 'region', 'roi', 'dispersion-quantile' };
anova_factors = setdiff( anova_factors, getcats(labels, 'un') );

anova_outs = dsp3.anovan( dispersions, labels', {}, anova_factors ...
  , 'remove_nonsignificant_comparisons', true ...
);

if ( params.do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( base_save_dir(params.config), 'dispersion-stats' );
  dsp3.req_savefig( gcf, save_p, prune(labels), anova_factors );
  
  stat_p = fullfile( save_p, 'stats' );
  dsp3.save_anova_outputs( anova_outs, stat_p, anova_factors );
end

end

function plot_heatmap(plt_counts, plt_labels, x_edges, y_edges, params)

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
  
  if ( ~isempty(params.c_lims) )
    shared_utils.plot.set_clims( ax, params.c_lims );
  end
end

if ( params.do_save )
  save_p = fullfile( base_save_dir(params.config), 'heatmaps' );
  img_formats = { 'epsc', 'png', 'fig', 'svg' };
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prune(plt_labels), pcats, '', img_formats );
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

function [data, labels, mask] = zscore_collapse2(data, labels, mask, per_unit)

zscore_each = { 'unit_uuid', 'session', 'region' };
z_I = findall( labels, zscore_each, mask );

for i = 1:numel(z_I)
  ind = z_I{i};
  tot = columnize( data(ind, :, :) );
  mu = nanmean( tot );
  dev = nanstd( tot );
  data(ind, :, :) = (data(ind, :, :) - mu) / dev;
end

if ( ~per_unit) 
  collapsecat( labels, {'unit_uuid', 'session'} );
end

end

function [data, labels, mask] = handle_unit_collapsing(data, labels, mask, params)

if ( params.zscore_collapse )
%   [data, labels, mask] = zscore_collapse( data, labels, mask );
  [data, labels, mask] = zscore_collapse2( data, labels, mask, params.per_unit );
end

if ( params.zero_one_normalize )
  abs_max = max( data(:) );
  abs_min = min( data(:) );
  
  data = (data - abs_min) ./ (abs_max - abs_min);
end

end

function deg = to_degrees(px, params)

info = params.monitor_info;
deg = hwwa.px2deg( px, info.height, info.distance, info.vertical_resolution );

end

function save_p = base_save_dir(conf)

save_p = fullfile( bfw.dataroot(conf), 'plots', 'binned_position_psth' ...
  , 'lower-res', dsp3.datedir );

end