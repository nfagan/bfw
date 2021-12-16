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

monitor_info = bfw_default_monitor_info();
to_degrees = ...
  @(px, info) hwwa.px2deg( px, info.height, info.distance, info.vertical_resolution );

%%

h = monitor_info.height;  % 27
d = monitor_info.distance;  % 50
r = monitor_info.vertical_resolution; % 768

deg_per_px = rad2deg(atan2(.5*h, d)) / (.5*r);

px = 20 / deg_per_px;

x = rad2deg(atan(27/2 * 1/50)) * 2 / 768;

deg = px * deg_per_px;

%%

% bin_size = 10;
% num_bins = 100;

bin_size = 40;
num_bins = 25;

spatial_outs = bfw_spatially_binned_events( ...
    'config', conf ...
  , 'is_parallel', false ...
  , 'bin_size', bin_size ...
  , 'num_bins', num_bins ...
  , 'select_rois', {'eyes_nf', 'face', 'right_nonsocial_object'} ...
);

possible_rois = combs( spatial_outs.labels, 'roi' );

%%

conf = bfw.set_dataroot( '~/Destkop/bfw' );

%%  based on spiking activity

bin_dir = '100_bins';
fix_grad_p = fullfile( bfw.dataroot(conf), 'analyses', 'fixation_position_gradient' );
fix_pos_p = fullfile( fix_grad_p, bin_dir );

spatial_outs = shared_utils.io.fload( fullfile(fix_pos_p, 'spatial_outs.mat') );
counts = load( fullfile(fix_pos_p, 'counts.mat') );

count_labels = counts.count_labels;
counts = counts.counts;

%%  based on behavior

dur_counts = load( fullfile(fix_grad_p, '100_bins_duration', 'counts.mat') );
dur_count_labels = dur_counts.count_labels;
dur_counts = dur_counts.counts;

fix_counts = load( fullfile(fix_grad_p, '100_bins_fix_counts', 'counts.mat') );
fix_count_labels = fix_counts.count_labels;
fix_counts = fix_counts.counts;

assert( dur_count_labels == count_labels && fix_count_labels == count_labels );

%%

cell_id_labels = bfw_ct.load_distance_model_cell_ids( conf );

%%

sessions = combs( spike_data.labels, 'session' );
all_counts = cell( numel(sessions), 1 );
all_labels = cell( numel(sessions), 1 );

% count_measure = 'spikes';
count_measure = 'events';

for i = 1:numel(sessions)
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
    , 'measure', count_measure ...
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
clims = [];
% clims = [-0.7, 0.5];
% deg_limits = [-20, 20];
deg_limits = [-20, 20];

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

base_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, {'eyes_nf', 'face', 'right_nonsocial_object'} ...
);

find_ns_obj = @(l) find(l, 'right_nonsocial_object');

% Exclude nonsocial-object samples from sessions preceding the actual
% introduction of the object.
mask_func = @(l, m) setdiff(...
  base_mask_func(l, m) ...
  , bfw.find_sessions_before_nonsocial_object_was_added(l, find_ns_obj(l)) ...
);

% disp_counts = fix_counts;
% disp_counts = dur_counts;
disp_counts = [];

has_behav_dispersion_counts = ~isempty( disp_counts );

bfw_plot_binned_position( counts, count_labels', spatial_outs ...
  , 'zscore_collapse', true ...
  , 'zero_one_normalize', false ...
  , 'per_unit', true ...
  , 'mask_func', mask_func ...
  , 'use_custom_rois', true ...
  , 'custom_rois', custom_rois ...
  , 'c_lims', clims ...
  , 'do_save', true ...
  , 'config', conf ...
  , 'invert_y', true ...
  , 'to_degrees', true ...
  , 'square_axes', true ...
  , 'smooth_func', @(x) imgaussfilt(x, 1.25) ...
  , 'plot_heatmap', false ...
  , 'normalize_xy_roi_info_to_bla', false ...
  , 'use_roi_center_for_dispersion', true ...
  , 'dispersion_x_deg_limits', deg_limits ...
  , 'dispersion_y_deg_limits', deg_limits ...
  , 'use_raw_counts_for_dispersion', true ...
  , 'dispersion_data', disp_counts ...
  , 'collapse_units_in_dispersion_stats', has_behav_dispersion_counts ...
  , 'per_dispersion_quantile', false ...
);

%%  dispersion scatter

x_edges = bfw.px2deg( spatial_outs.x_edges(1, :) );
y_edges = bfw.px2deg( spatial_outs.y_edges(1, :) );
[x_edges, y_edges] = meshgrid( x_edges, y_edges );
disp_len = vecnorm( cat(3, x_edges, y_edges), 2, 3 );

disp_counts = zeros( size(counts, 1), 1 );
exclude_zeros_spikes = true;

all_info = [];
all_info_labels = fcat();

for i = i:size(counts, 1)
  shared_utils.general.progress( i, size(counts, 1) );
  
  one_counts = squeeze( counts(i, :, :) );
  non_empty_counts = one_counts > 0;
  
  all_counts = reshape( one_counts, [], 1 );
  all_lens = reshape( disp_len, [], 1 );
  
  if ( exclude_zeros_spikes )
    is_zero = all_counts == 0;
    all_counts(is_zero) = [];
    all_lens(is_zero) = [];
  end
  
  tmp_labs = append1( fcat, count_labels, i, numel(all_lens) );
  all_info = [ all_info; [all_counts, all_lens] ];
  append( all_info_labels, tmp_labs );
  
  assert_ispair( all_info, all_info_labels );
  
%   all_disp_counts = one_counts .* disp_len;
%   all_disp_counts = one_counts ./ disp_len;
%   non_empty_counts = non_empty_counts & disp_len > 0;
  
%   all_disp_counts = reshape( all_disp_counts(non_empty_counts), [], 1 );  
%   disp_counts(i) = nanmean( all_disp_counts(:) );
end

%%  dispersion

x_edges = bfw.px2deg( spatial_outs.x_edges(1, :) );
y_edges = bfw.px2deg( spatial_outs.y_edges(1, :) );
[x_edges, y_edges] = meshgrid( x_edges, y_edges );
disp_len = vecnorm( cat(3, x_edges, y_edges), 2, 3 );

z_counts = counts;
for i = 1:size(z_counts, 1)
  tmp = z_counts(i, :, :);
  mu = nanmean( tmp );
  sig = nanstd( tmp );
  
  if ( sig == 0 )
    z_counts(i, :, :) = nan;
  else
    z_counts(i, :, :) = (tmp - mu) ./ sig;
  end
end

disp_counts = zeros( size(counts, 1), 1 );
exclude_zeros_spikes = true;
use_z_counts = true;

for i = 1:size(counts, 1)
  shared_utils.general.progress( i, size(counts, 1) );
  
  if ( use_z_counts )
    one_counts = squeeze( z_counts(i, :, :) );
  else
    one_counts = squeeze( counts(i, :, :) );
  end
  
  if ( exclude_zeros_spikes )
    non_empty_counts = one_counts > 0;
  else
    non_empty_counts = true( size(one_counts) );
  end
  
  all_disp_counts = one_counts .* disp_len;
  all_disp_counts = reshape( all_disp_counts(non_empty_counts), [], 1 );  
  
  disp_counts(i) = nanmean( all_disp_counts(:) );
end

%%  plot dispersion

do_save = true;

pl = plotlabeled.make_common();
pl.hist_add_summary_line = true;
pl.summary_func = @nanmedian;

plt_mask = mask_func( count_labels, rowmask(count_labels) );
plt_counts = disp_counts(plt_mask);
plt_labels = prune( count_labels(plt_mask) );

fcats = { 'region' };
pcats = { 'roi', 'region' };
[figs, axs, fig_I] = pl.figures( @hist, plt_counts, plt_labels, fcats, pcats );
shared_utils.plot.match_ylims( axs );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots/binned_position_psth/dispersion-spike_over_distance' ...
    , dsp3.datedir );
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(plt_labels(fig_I{i})), [fcats, pcats] );
  end
end

%%  Scatter dispersion 

do_save = false;
assert_ispair( all_info, all_info_labels );

fcats = { 'region' };
gcats = { 'roi' };
pcats = { 'region' };

plt_mask = mask_func( all_info_labels, rowmask(all_info_labels) );
plt_mask = find( all_info_labels, 'bla', plt_mask );

fig_I = findall( all_info_labels, fcats, plt_mask );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.hist_add_summary_line = true;
  pl.summary_func = @nanmedian;
  
  xs = all_info(fig_I{i}, 1);
  ys = all_info(fig_I{i}, 2);
  ls = all_info_labels(fig_I{i});
  
  [axs, ids] = pl.scatter( xs, ys, ls, gcats, pcats );
end

% fig_I = findall( 

%%

do_save = true;
zscore_collapse = true;
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
  , @findor, setdiff(possible_rois, 'left_nonsocial_object') ...
);

if ( zscore_collapse )
  zscore_each = { 'unit_uuid', 'session', 'region', 'roi' };
%   mean_each = { 'region', 'roi' };
  mean_each = zscore_each;
  
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
  plt_x_edges = to_degrees( x_edges, monitor_info );
  plt_y_edges = to_degrees( y_edges, monitor_info );

  plt_cats = { 'unit_uuid', 'roi', 'region' };
  axs = pl.imagesc( plt_counts, plt_labels, plt_cats );
  shared_utils.plot.tseries_xticks( axs, round(plt_x_edges), 10 );
  shared_utils.plot.fseries_yticks( axs, round(flip(plt_y_edges)), 10 );
  shared_utils.plot.hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, find(plt_x_edges == 0) );
  shared_utils.plot.add_horizontal_lines( axs, find(plt_y_edges == 0) );

  if ( ~zscore_collapse || ismember('unit_uuid', mean_each) )
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
  
  for i = 1:numel(axs)
    axis( axs(i), 'square' );
  end
  
  if ( do_save )
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, prune(plt_labels), plt_cats, '', {'epsc', 'png', 'fig', 'svg'} );
  end
end

%%

