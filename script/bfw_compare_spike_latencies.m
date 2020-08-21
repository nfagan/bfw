%%

conf = bfw.set_dataroot( '~/Desktop/bfw' );

%%  50ms win, 50ms step

gaze_counts = ...
  shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_lda/reward_gaze_spikes/for_anova_class/gaze_counts.mat') );

%%  50ms win, 10ms step

gaze_counts = ...
  shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_latency/counts/gaze_counts_01.mat') );

%%

sig_anova_ids = shared_utils.io.fload( '/Users/Nick/Desktop/sig_anova_ids.mat' );

%%

exclude_last_time_bin = false;
% subset_t_lims = [-0.5, 0.5];
subset_t_lims = [-0.25, 0.25];
smooth_amount = 0;

spikes = gaze_counts.spikes;
labels = gaze_counts.labels';

[~, transform_ind] = bfw.make_whole_face_roi( labels );
spikes = spikes(transform_ind, :);
time = gaze_counts.t;

subset_t = time >= subset_t_lims(1) & time <= subset_t_lims(2);
spikes = spikes(:, subset_t);
time = time(subset_t);

if ( exclude_last_time_bin )
  spikes = spikes(:, 1:end-1);
  time = time(1:end-1);
end

if ( smooth_amount > 0 )
  
end

%%

only_significant_cells = false;

mask = fcat.mask( labels ...
  , @findnone, bfw.nan_unit_uuid ...
  , @find, {'m1', 'mutual'} ...
  , @find, {'nonsocial_object_eyes_nf_matched'} ...
);

if ( only_significant_cells )
  mask = findor( labels, sig_anova_ids, mask );
end

%%

smooth_spikes = spikes;

mean_each = { 'unit_uuid', 'session', 'region', 'roi' };
[mean_labs, mean_I] = keepeach( labels', mean_each, mask );
mean_spikes = bfw.row_nanmean( smooth_spikes, mean_I );

[~, peak_ind] = max( mean_spikes, [], 2 );
peak_ts = time(peak_ind);
peak_mat = full( sparse(1:numel(peak_ind), peak_ind, true) );

is_pre = peak_ts < 0;
is_post = peak_ts >= 0;

if ( ~exclude_last_time_bin )
  % discard last time bin of post to ensure pre and post have 
  % equal number of bins.
  is_post = is_post & peak_ts < time(end);
end

%%  proportion pre vs. post

pre_post_labels = mean_labs';
% addcat( pre_post_labels, 'peak-period' );
addsetcat( pre_post_labels, 'peak-period', 'post' );
setcat( pre_post_labels, 'peak-period', 'pre', find(is_pre) );
setcat( pre_post_labels, 'peak-period', 'post', find(is_post) );

[props, prop_labels] = proportions_of( pre_post_labels, 'region', 'peak-period' );

pl = plotlabeled.make_common();
axs = pl.bar( props, prop_labels, 'region', 'peak-period', {} );

%%  peak-average

pl = plotlabeled.make_common();
axs = pl.bar( peak_ts(:), mean_labs, 'region', {}, {} );
% axs = pl.boxplot( peak_ts(:), mean_labs, 'region', {} );

%%  peak-hist

pl = plotlabeled.make_common();
pl.hist_add_summary_line = true;
pl.summary_func = @nanmedian;
axs = pl.hist( peak_ts(:), mean_labs, 'region', 30 );

%%  time / peak distribution

pcats = {'region', 'roi'};
[p_I, p_C] = findall( mean_labs, pcats );
axs = gobjects( size(p_I) );
shp = plotlabeled.get_subplot_shape( numel(p_I) );

plot_spectra = true;
do_save = true;
ylims = [ 0, 0.04 ];

clf();

for i = 1:numel(p_I)
  ax = subplot( shp(1), shp(2), i );
  cla( ax );
  axs(i) = ax;
  
  subset_peaks = peak_mat(p_I{i}, :);
  subset_peaks = imgaussfilt( double(subset_peaks), 1.5 );
  subset_peak_ts = peak_ts(p_I{i});
  
  [~, sort_ind] = sort( subset_peak_ts );
  subset_peaks = subset_peaks(sort_ind, :);
  
  trace = nanmean( subset_peaks, 1 );
  
  if ( plot_spectra )
    h = imagesc( ax, time, 1:size(subset_peaks, 2), subset_peaks );
    colorbar;
  else
    h = plot( ax, time, trace );
    set( ax, 'ylim', ylims );
  end
  
  title_labs = strrep( strjoin(p_C(:, i), ' | '), '_' , ' ' );
  title( title_labs );
  
  med_peak = nanmedian( subset_peak_ts );
  p_less = signrank( subset_peak_ts, 0, 'tail', 'left' );
  p_greater = signrank( subset_peak_ts, 0, 'tail', 'right' );
  
  med_text = sprintf( 'M = %0.2f | p-less: %0.3f; p-greater: %0.3f' ...
    , med_peak, p_less, p_greater );
  
  hold( ax, 'on' );
  shared_utils.plot.add_vertical_lines( ax, med_peak );
  
  if ( plot_spectra )
    th = text( ax, med_peak, mean(get(ax, 'ylim')), med_text );
    th.Color = 'white';
    th.FontSize = 14;
    th.HorizontalAlignment = 'center';
  end
end

anova_results = dsp3.anova1( peak_ts(:), mean_labs, {'roi'}, 'region' ...
  , 'remove_nonsignificant_comparisons', false ...
);

if ( do_save )
  subdirs = {};

  if ( only_significant_cells )
    subdirs{end+1} = 'sig_only';
  else
    subdirs{end+1} = 'all_cells';
  end
  
  plot_type = ternary( plot_spectra, 'spectra', 'lines' );
  
  save_p = fullfile( bfw.dataroot(conf), 'plots/spike_latency', dsp3.datedir ...
    , subdirs{:} );
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, mean_labs, pcats, plot_type );
end

%%  new

rois = { 'whole_face', 'eyes_nf', 'nonsocial_object_eyes_nf_matched' };
plot_spectra = trufls;
only_significant_cells = trufls;

cs = dsp3.numel_combvec( rois, plot_spectra, only_significant_cells );

for i = 1:size(cs, 2)
  shared_utils.general.progress( i, size(cs, 2) );
  
  base_subdir = sprintf( '%0.2f, %0.2f', subset_t_lims(1), subset_t_lims(2) );
  
  c = cs(:, i);
  roi = rois{c(1)};
  do_plot_spectra = plot_spectra(c(2));
  is_only_significant_cells = only_significant_cells(c(3));

  mask_func = @(l, m) fcat.mask( l, m ...
    , @findnone, bfw.nan_unit_uuid ...
    , @find, {'m1', 'mutual'} ...
    , @find, roi ...
  );

  if ( is_only_significant_cells )
    mask_func = @(l, m) fcat.mask(l, mask_func(l, m) ...
      , @findor, sig_anova_ids ...
    );

    base_subdir = fullfile( base_subdir, 'sig_only' );
  else
    base_subdir = fullfile( base_subdir, 'all_cells' );
  end

  bfw_plot_spike_latencies( spikes, labels', time ...
    , 'mask_func', mask_func ...
    , 'config', conf ...
    , 'base_subdir', base_subdir ...
    , 'do_save', true ...
    , 'spectra', do_plot_spectra ...
  );
end
