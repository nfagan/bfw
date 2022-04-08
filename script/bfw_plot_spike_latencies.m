function bfw_plot_spike_latencies(spikes, labels, time, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.plot_type = 'spectra';
defaults.fig = gcf();
defaults.y_lims = [ 0, 0.04 ];
defaults.c_lims = [];
defaults.target_categories = { 'roi' };
defaults.hist_pcats = { 'roi' };
defaults.hist_gcats = { 'region' };
defaults.anova_each = { 'region' };
defaults.anova_categories = { 'roi' };
defaults.imgauss_filter_spectra = true;
defaults.first_trial_average = true;
defaults.exclude_all_zero_trials = false;
defaults.ordered_points_for_cell = false;
defaults.n_sem_threshold = 2;
defaults.hist_smooth_func = [];

params = bfw.parsestruct( defaults, varargin );

target_cats = params.target_categories;
plot_type = validatestring( params.plot_type, allowed_plot_types() );
params.plot_type = plot_type;

assert_ispair( spikes, labels );
assert( numel(time) == size(spikes, 2), 'Time does not correspond to spikes.' );

mask = get_mask( labels, params );

if ( params.exclude_all_zero_trials )
  zero_trials = all( spikes == 0, 2 );
  mask = intersect( mask, find(~zero_trials) );
end

if ( params.first_trial_average )
  [mean_spikes, mean_labs] = get_mean_spikes( spikes, labels', target_cats, mask );
else
  mean_spikes = spikes(mask, :);
  mean_labs = labels(mask);
end

[peak_ts, peak_mat] = get_peak_times( mean_spikes, time );
cell_meets_crit = false( rows(peak_mat), 1 );
for i = 1:rows(cell_meets_crit)
  cell_meets_crit(i) = is_peak_above_sem( peak_mat(i, :), mean_spikes(i, :), params.n_sem_threshold );
end

if ( ~params.first_trial_average )
  peak_ts = peak_ts(:);
  peak_ts = get_mean_spikes( peak_ts, mean_labs', target_cats, rowmask(peak_ts) );
  [peak_mat, mean_labs] = ...
    get_mean_spikes( double(peak_mat), mean_labs', target_cats, rowmask(peak_mat) );
end

if ( ismember(plot_type, {'spectra', 'lines'}) )
  plot_spectra_or_lines( peak_ts, peak_mat, time, mean_labs', params );
  
elseif ( strcmp(plot_type, 'hist') )
  plot_cumulative_hist( peak_ts(:), peak_mat, time, mean_labs', params );
  
% elseif ( strcmp(plot_type, 'bars') )
%   plot_mean_bars( peak_ts(:), mean_labs', params );
  
elseif ( ismember(plot_type, {'violin', 'bars'}) )
  plot_mean( peak_ts(:), mean_labs', plot_type, params );
  
else
  error( 'Unrecognized plot type "%s".', plot_type );
end

end

function [prop, labs] = to_cumulative_prop(peak_mat, time, labels, mask)

cum_mat = false( numel(mask), size(peak_mat, 2) );
num_non_empty = 0;

for i = 1:numel(mask)
  peak_ind = find( peak_mat(mask(i), :) );
  
  if ( ~isempty(peak_ind) )
    num_non_empty = num_non_empty + 1;
    cum_mat(i, peak_ind:end) = true;
  end
end

prop = sum( cum_mat, 1 ) / num_non_empty;
labs = append1( fcat, labels, mask );

end

function [props, labs] = make_cumulative_proportion(peak_mat, time, labels, prop_I)

props = cell( size(prop_I) );
labs = cell( size(prop_I) );

for i = 1:numel(prop_I)
  [props{i}, labs{i}] = ...
    to_cumulative_prop( peak_mat, time, labels, prop_I{i} );
end

props = vertcat( props{:} );
labs = vertcat( fcat, labs{:} );

end

function plot_cumulative_hist(peak_ts, peak_mat, time, labels, params)

prop_I = findall( labels, [{'region'}, params.target_categories] );
[props, labs] = make_cumulative_proportion( peak_mat, time, labels, prop_I );

%%

if ( isempty(props) )
  warning( 'Data were empty.' );
  return;
end

pl = plotlabeled.make_common();
pl.x = time;

if ( ~isempty(params.hist_smooth_func) )
  pl.smooth_func = params.hist_smooth_func;
  pl.add_smoothing = true;
end

gcats = params.hist_gcats;
pcats = params.hist_pcats;

axs = pl.lines( props, labs, gcats, pcats );
shared_utils.plot.hold( axs, 'on' );

for i = 1:numel(axs)
  x = get( axs(i), 'xlim' );
  y = get( axs(i), 'ylim' );
  xs = linspace( x(1), x(2), 20 );
  ys = linspace( y(1), y(2), 20 );
  plot( axs(i), xs, ys, 'k--' );
end

if ( params.do_save )
  subdirs = {};
  plot_type = 'cumulative_prop';
  save_p = get_save_p( params, subdirs );
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, labs, csunion(pcats, gcats), plot_type );
end

end

function plot_mean_bars(peak_ts, mean_labs, params)

%%

pl = plotlabeled.make_common();

pcats = { 'joint-event-type' };
gcats = { 'initiated-by' };
xcats = { 'region' };

axs = pl.bar( peak_ts, mean_labs, xcats, gcats, pcats );
ylabel( axs(1), 'Mean time of peak firing rate (s)' );

ttest_results = dsp3.ttest2( peak_ts, mean_labs', xcats, 'm1-init', 'm2-init' );

if ( params.do_save )
  subdirs = {};
  plot_type = 'bars';
  save_p = get_save_p( params, subdirs );
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, mean_labs, pcats, plot_type );
  
  dsp3.save_ttest2_outputs( ttest_results, fullfile(save_p, 'stats'), xcats );
end

end

function plot_mean(peak_ts, mean_labs, plot_type, params)

%%

pl = plotlabeled.make_common();

if ( strcmp(plot_type, 'violin') )
  pl.group_order = { 'bla', 'ofc', 'accg', 'dmpfc' };

  pcats = { 'roi' };
  gcats = { 'region' };

  axs = pl.violinalt( peak_ts, mean_labs, gcats, pcats );
  
elseif ( strcmp(plot_type, 'bars') )
  pl.group_order = { 'bla', 'ofc', 'accg', 'dmpfc' };

  pcats = { 'roi' };
  gcats = { 'region' };

  axs = pl.bar( peak_ts, mean_labs, {}, gcats, pcats );
  
else
  error( 'Unrecognized plot type "%s".', plot_type );
end
  
ylabel( axs(1), 'Mean time of peak firing rate (s)' );

if ( ~isempty(params.y_lims) )
  shared_utils.plot.set_ylims( axs, params.y_lims );
end

if ( params.do_save )
  subdirs = {};
  save_p = get_save_p( params, subdirs );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, mean_labs, pcats, plot_type );
end

end

function plot_spectra_or_lines(peak_ts, peak_mat, time, mean_labs, params)

pcats = [{'region'}, params.target_categories];
[p_I, p_C] = findall( mean_labs, pcats );
axs = gobjects( size(p_I) );
shp = plotlabeled.get_subplot_shape( numel(p_I) );

plot_spectra = strcmp( params.plot_type, 'spectra' );
ylims = params.y_lims;
fig = params.fig;
clf( fig );

for i = 1:numel(p_I)
  ax = subplot( shp(1), shp(2), i );
  cla( ax );
  axs(i) = ax;
  
  subset_peaks = double( peak_mat(p_I{i}, :) );
  
  if ( params.imgauss_filter_spectra )
    subset_peaks = imgaussfilt( subset_peaks, 1.5 );
  end
  
  subset_peak_ts = peak_ts(p_I{i});
  
  [~, sort_ind] = sort( subset_peak_ts );
  subset_peaks = subset_peaks(sort_ind, :);
  
  trace = nanmean( subset_peaks, 1 );
  
  if ( plot_spectra )
    if ( params.ordered_points_for_cell )
      hs = gobjects( size(subset_peaks, 1), 1 );
      
      for j = 1:size(subset_peaks, 1)
        frac_j = 1 - (j-1) / size(subset_peaks, 1);
        hs(j) = plot( ax, time(logical(subset_peaks(j, :))), frac_j, 'ko' );
        hold( ax, 'on' );
      end      
    else
      h = imagesc( ax, time, 1:size(subset_peaks, 2), subset_peaks );
      colorbar;
    end
  else
    h = plot( ax, time, trace );
    if ( ~isempty(ylims) )
      set( ax, 'ylim', ylims );
    end
  end
  
  title_labs = strrep( strjoin(p_C(:, i), ' | '), '_' , ' ' );
  title( title_labs );
  
  med_peak = nanmedian( subset_peak_ts );
  p_less = signrank( subset_peak_ts, 0, 'tail', 'left' );
  p_greater = signrank( subset_peak_ts, 0, 'tail', 'right' );
  
  med_text = sprintf( 'M = %0.2f | p-less: %0.3f; p-greater: %0.3f' ...
    , med_peak, p_less, p_greater );
  
  hold( ax, 'on' );
  v_line_hs = shared_utils.plot.add_vertical_lines( ax, med_peak ); 
  
  if ( plot_spectra )
    for j = 1:numel(v_line_hs)
      set( v_line_hs(j), 'color', [1, 1, 1] );
    end
  end
  
  if ( plot_spectra )
    th = text( ax, med_peak, mean(get(ax, 'ylim')), med_text );
    th.Color = 'white';
    th.FontSize = 14;
    th.HorizontalAlignment = 'center';
  end
end

if ( ~isempty(params.c_lims) )
  shared_utils.plot.set_clims( axs, params.c_lims );
end


rois = combs( mean_labs, 'roi' );
ttest_outs = [];
rs_outs = [];
anova_results = [];

compare_regions = true;
if ( compare_regions )
  anova_results = dsp3.anova1( peak_ts(:), mean_labs, params.target_categories, 'region' ...
    , 'remove_nonsignificant_comparisons', false ...
  );
end

if ( numel(rois) == 2 )
  ttest_outs = dsp3.ttest2( peak_ts(:), mean_labs, 'region', rois{1}, rois{2} );
  setcat( ttest_outs.t_labels, 'roi', sprintf('%s_%s', rois{1}, rois{2}) );
  rs_outs = dsp3.ranksum( peak_ts(:), mean_labs, 'region', rois{1}, rois{2} );
  setcat( rs_outs.rs_labels, 'roi', sprintf('%s_%s', rois{1}, rois{2}) );
elseif ( ~compare_regions )
  anova_results = dsp3.anova1( peak_ts(:), mean_labs, 'region', 'roi' ...
    , 'remove_nonsignificant_comparisons', false ...
  );
end

% anova_results = dsp3.anovan( peak_ts(:), mean_labs, params.anova_each ...
%   , params.anova_categories ...
%   , 'remove_nonsignificant_comparisons', false ...
% );

if ( params.do_save )
  subdirs = {};
  plot_type = ternary( plot_spectra, 'spectra', 'lines' );
  save_p = get_save_p( params, subdirs );
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, mean_labs, pcats, plot_type );
  
  if ( ~isempty(anova_results) )
    dsp3.save_anova_outputs( anova_results, fullfile(save_p, 'stats'), pcats );
  end
  if ( ~isempty(ttest_outs) )
    dsp3.save_ttest2_outputs( ttest_outs, fullfile(save_p, 'stats'), pcats );
  end
  if ( ~isempty(rs_outs) )
    dsp3.save_ranksum_outputs( rs_outs, fullfile(save_p, 'stats'), pcats );
  end
end

end

function save_p = get_save_p(params, subdirs)

save_p = fullfile( bfw.dataroot(params.config) ...
  , 'plots/spike_latency', dsp3.datedir, params.base_subdir, subdirs{:} );

end

function [mean_spikes, labels] = get_mean_spikes(spikes, labels, target_categories, mask)

mean_each = union( {'unit_uuid', 'session', 'region'}, target_categories );

[~, mean_I] = keepeach( labels, mean_each, mask );
mean_spikes = bfw.row_nanmean( spikes, mean_I );

end

function [peak_ts, peak_mat] = get_peak_times(mean_spikes, time)

[~, peak_ind] = max( mean_spikes, [], 2 );
peak_ts = time(peak_ind);

peak_mat = false( size(mean_spikes) );
for i = 1:numel(peak_ind)
  peak_mat(i, peak_ind(i)) = true;
end

% peak_mat = full( sparse(1:numel(peak_ind), peak_ind, true) );

end

function mask = get_mask(labels, params)

mask = params.mask_func( labels, rowmask(labels) );

end

function tf = is_peak_above_sem(peak_vec, psth_vec, n_sems)

assert( isequal(size(peak_vec), size(psth_vec)) );
assert( nnz(peak_vec) == 1 );

% sem = plotlabeled.sem( psth_vec(:) );
sigma = std( psth_vec );
mu = mean( psth_vec );
% tf = psth_vec(peak_vec) >= mu + sem * n_sems;
tf = psth_vec(peak_vec) >= mu + sigma * n_sems;

end

function types = allowed_plot_types()

types = {'spectra', 'lines', 'hist', 'bars', 'violin'};

end