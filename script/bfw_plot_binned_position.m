function bfw_plot_binned_position(counts, count_labels, spatial_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.zscore_collapse = false;
defaults.mask_func = @(l, m) m;

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

plt_mask = get_base_mask( use_labels, params.mask_func );
[use_data, use_labels, plt_mask] = handle_unit_collapsing( use_data, use_labels, plt_mask, params );

figs_each = { 'unit_uuid', 'session', 'region' };
fig_I = findall_or_one( use_labels, figs_each, plt_mask );

possible_rois = combs( spatial_outs.labels, 'roi' );

for idx = 1:numel(fig_I)
  fig_mask = fig_I{idx};

  plt_counts = use_data(fig_mask, :, :);
  plt_labels = use_labels(fig_mask);

  plt_cats = { 'unit_uuid', 'roi', 'region' };
  axs = pl.imagesc( plt_counts, plt_labels, plt_cats );
  
  shared_utils.plot.tseries_xticks( axs, x_edges, 10 );
  shared_utils.plot.fseries_yticks( axs, flip(y_edges), 10 );
  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, find(x_edges == 0) );
  shared_utils.plot.add_horizontal_lines( axs, find(y_edges == 0) );

  if ( ~params.zscore_collapse )
    add_rois( axs, spatial_outs, x_edges, y_edges, use_labels, possible_rois, fig_mask );
  end
  
  if ( params.do_save )
    img_formats = { 'epsc', 'png', 'fig', 'svg' };
    dsp3.req_savefig( gcf, save_p, prune(plt_labels), plt_cats, '', img_formats );
  end
end

end

function add_rois(axs, spatial_outs, x_edges, y_edges, use_labels, possible_rois, fig_mask)

for i = 1:numel(axs)
  ax = axs(i);
  title_labels = strrep( strsplit(get(get(ax, 'title'), 'string'), ' | '), ' ', '_' );
  roi = title_labels(ismember(title_labels, possible_rois));

  roi_ind = fcat.mask( spatial_outs.labels ...
    , @find, roi ...
    , @find, combs(use_labels, 'session', fig_mask) ...
  );

  rect = unique( spatial_outs.relative_rois(roi_ind, :), 'rows' );
  assert( rows(rect) == 1 );

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

collapsecat( labels, setdiff(zscore_each, mean_each) );
mask = rowmask( labels );

end

function [data, labels, mask] = handle_unit_collapsing(data, labels, mask, params)

if ( params.zscore_collapse )
  [data, labels, mask] = zscore_collapse( data, labels, mask );
end

end