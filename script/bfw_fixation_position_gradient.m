%%

conf = bfw.config.load();
spike_data = bfw_gather_spikes( ...
  'config', conf ...
  , 'spike_subdir', 'cc_spikes' ...
  , 'is_parallel', true ...
);

bfw.add_monk_labels( spike_data.labels );

%%

monitor_info = bfw_default_monitor_info();
bin_size_deg = hwwa.px2deg( 1000, monitor_info.height, monitor_info.distance, monitor_info.vertical_resolution )

%%

bin_size = 10;
num_bins = 100;

% bin_size = 20;
% num_bins = 50;

spatial_outs = bfw_spatially_binned_events( ...
    'config', conf ...
  , 'is_parallel', false ...
  , 'bin_size', bin_size ...
  , 'num_bins', num_bins ...
  , 'select_rois', {'eyes_nf', 'face', 'left_nonsocial_object', 'right_nonsocial_object'} ...
);

possible_rois = combs( spatial_outs.labels, 'roi' );

%%

cell_id_labels = bfw_ct.load_distance_model_cell_ids( conf );

%%

sessions = combs( spike_data.labels, 'session' );
all_counts = cell( numel(sessions), 1 );
all_labels = cell( numel(sessions), 1 );

parfor i = 1:numel(sessions)
  shared_utils.general.progress( i, numel(sessions) );
  
  unit_mask_func = @(labels, varargin) fcat.mask( labels, varargin{:} ...
    , @findnone, bfw.nan_unit_uuid() ...
    , @find, sessions{i} ...
  );

  % unit_id = 'unit_uuid__1202';

  spatial_mask_func = @(labels, mask) fcat.mask( labels, mask );

  [counts, count_labels] = bfw_aggregate_spatial_bins( spike_data, spatial_outs ...
    , 'unit_mask_func', unit_mask_func ...
    , 'spatial_mask_func', spatial_mask_func ...
    , 'measure', 'spikes' ...
  );  

  all_counts{i} = counts;
  all_labels{i} = count_labels;
end

counts = vertcat( all_counts{:} );
count_labels = vertcat( fcat(), all_labels{:} );

%%

custom_rois = containers.Map();
custom_roi_names = { 'eyes_nf', 'face', 'right_nonsocial_object' };
max_ares = containers.Map();

for i = 1:numel(custom_roi_names)  
  roi_ind = find( spatial_outs.labels, custom_roi_names{i} );
  rois = spatial_outs.relative_rois(roi_ind, :);
  frac_rois = spatial_outs.fractional_rois(roi_ind, :);
  
  ws = shared_utils.rect.width( frac_rois );
  hs = shared_utils.rect.height( frac_rois );
  areas = ws .* hs;
  [~, max_ind] = max( areas );
  
  mins = min( rois(:, [1, 2]), [], 1 );
  maxs = max( rois(:, [3, 4]), [], 1 );
  ws = shared_utils.rect.width( rois );
  hs = shared_utils.rect.height( rois );
  areas = ws .* hs;
  [~, largest_ind] = max( areas );
  union_roi = [ mins, maxs ];
  largest_roi = rois(largest_ind, :);
  assert( isequal(union_roi, largest_roi) );
  
%   custom_rois(custom_roi_names{i}) = union_roi;
  custom_rois(custom_roi_names{i}) = frac_rois(max_ind, :);
end

bfw_plot_binned_position( counts, count_labels', spatial_outs ...
  , 'zscore_collapse', true ...
  , 'mask_func', @(l, m) find(l, {'eyes_nf', 'face', 'right_nonsocial_object'}, m) ...
  , 'use_custom_rois', true ...
  , 'custom_rois', custom_rois ...
  , 'c_lims', [-0.45, 0.57] ...
  , 'do_save', true ...
  , 'config', bfw.set_dataroot('~/Desktop/bfw') ...
  , 'invert_y', true ...
  , 'to_degrees', true ...
  , 'square_axes', true ...
  , 'smooth_func', @(x) imgaussfilt(x, 1.25) ...
);

%%

do_save = true;
zscore_collapse = false;
save_p = fullfile( bfw.dataroot(conf), 'plots', 'binned_position_psth', 'lower-res', dsp3.datedir );

use_labels = count_labels';
use_data = counts;

x_edges = spatial_outs.x_edges(1, :);
y_edges = spatial_outs.y_edges(1, :);

pl = plotlabeled.make_spectrogram( x_edges, y_edges );
pl.fig = figure(2);
pl.add_smoothing = true;
% pl.smooth_func = @(x) imgaussfilt( x, 1.2 );

plt_mask = fcat.mask( use_labels ...
%{
%   , @find, ref(combs(count_labels, 'unit_uuid'), '{}', 3) ...
%}
);

if ( zscore_collapse )
  zscore_each = { 'unit_uuid', 'session', 'region', 'roi' };
  mean_each = { 'region', 'roi' };
  
  z_I = findall( use_labels, zscore_each, plt_mask );
  for i = 1:numel(z_I)
    subset = use_data(z_I{i}, :, :);
    use_data(z_I{i}, :, :) = (subset - nanmean(subset(:))) ./ nanstd( subset(:) );
  end
  
  [~, I] = keepeach( use_labels, mean_each, plt_mask );
  use_data = bfw.row_nanmean( use_data, I );
  
  collapsecat( use_labels, setdiff(zscore_each, mean_each) );
  plt_mask = rowmask( use_labels );
end

figs_each = { 'unit_uuid', 'session', 'region' };
fig_I = findall_or_one( use_labels, figs_each, plt_mask );

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

  if ( ~zscore_collapse )
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
  
  if ( do_save )
    dsp3.req_savefig( gcf, save_p, prune(plt_labels), plt_cats, '', {'epsc', 'png', 'fig', 'svg'} );
  end
end

%%

