function plot_granger(granger_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @(l, m) m;
defaults.plot_time_series = true;
defaults.plot_average = true;
defaults.plot_epochs = true;
defaults.epoch_granger_value_threshold = 1e3;
defaults.epoch_window_offset = 1;
defaults.max_num_epoch_windows = inf;

params = bfw.parsestruct( defaults, varargin );

g_labels = granger_outs.granger_labels';
traces = granger_outs.smoothed_traces;
g_fs = granger_outs.granger_fs;
cvs = granger_outs.granver_cvs;
null_fs = shared_utils.struct.field_or( granger_outs, 'null_fs', [] );
null_cvs = shared_utils.struct.field_or( granger_outs, 'null_cs', [] );
sums = granger_outs.sums;

mask = get_base_mask( g_labels, params.mask_func );

if ( params.plot_epochs )
  plot_epochs( g_fs, cvs, null_fs, null_cvs, traces, g_labels', mask, params );
end

if ( params.plot_average )
  plot_average( g_fs, g_labels', mask, params );
end

if ( params.plot_time_series )
  plot_over_time_per_run( g_fs, sums, g_labels', mask, params );
end

end

function plot_epochs(g_fs, cvs, null_fs, null_cvs, traces, labels, mask, params)

fcats = { 'unified_filename' };
fig_I = findall_or_one( labels, fcats, mask );

fig = figure( 1 );

for i = 1:numel(fig_I)
  plot_epochs_one_run( fig, g_fs, cvs, null_fs, null_cvs ...
    , traces, labels, fig_I{i}, params );
end

end

function plot_epochs_one_run(fig, g_fs, cvs, null_fs, null_cvs, traces ...
  , labels, mask, params)

g = g_fs(mask, :);
cv = cvs(mask, :);

trace = traces(mask, :);
trace_maxima = cellfun( @(x) conditional(@() isempty(x), @nan, @() max(x)), trace );

above_thresh = g > params.epoch_granger_value_threshold;
start_info = cell( rows(g), 1 );

for i = 1:rows(g)
  [start, dur] = shared_utils.logical.find_islands( above_thresh(i, :) );
  start_info{i} = [start(:), dur(:)];
end

for i = 1:numel(start_info)
  ax = subplot( 2, 1, i );
  cla( ax );
  hold( ax, 'on' );
  
  starts = start_info{i}(:, 1);
  durs = start_info{i}(:, 2);
  window_inds = cat_expanded( 2, ...
    arrayfun(@(x, y) x:(x+y-1), starts, durs, 'un', 0) );
  
  max_g = max( arrayfun(@(x) max(g(:, x), [], 1), window_inds) );
  tot_max = max( arrayfun(@(x) max(trace_maxima(:, x), [], 1), window_inds) );
  
  offset = 0;
  
  ewo = params.epoch_window_offset;
  max_num_wins = params.max_num_epoch_windows;
  
  for j = ewo:min(numel(window_inds), ewo+max_num_wins)
    win_ind = window_inds(j);
    
    granger_win = g(i, win_ind);
    cv_win = cv(i, win_ind);
    
    trace_win1 = trace{1, win_ind};
    trace_win2 = trace{2, win_ind};
    
    x = (1:numel(trace_win1)) + offset;
    offset = offset + numel( trace_win1 ) + 1e3;
    
    mean_x = mean( x );
    
    plot( ax, x, trace_win1, 'r', 'LineWidth', 2 );
    plot( ax, x, trace_win2, 'b', 'LineWidth', 2 );
    ylim( ax, [0, tot_max] );
    
    g_frac_max = granger_win / max_g;
    g_projected = tot_max * g_frac_max;
    text_offset = 0.05 * tot_max;
    
    if ( ~isempty(null_fs) )
      null_dist = null_fs{mask(i), win_ind};
      null_p_val = 1 - pnz( granger_win > null_dist );
    else
      null_p_val = nan;
    end
    
    g_text = sprintf('G=%0.2f', granger_win );
    cv_text = sprintf( 'CV=%0.2f', cv_win );
    sig_text = ternary( granger_win > cv_win, '**', '' );
    pval_text = sprintf( 'p=%0.2f', null_p_val );
    use_text = sprintf( '%s;%s%s (%s)', g_text, cv_text, sig_text, pval_text );
    
    plot( ax, mean_x, g_projected, 'k*', 'MarkerSize', 3 );
    text( ax, mean_x, g_projected+text_offset, use_text ); 
    
    legend( {'m1', 'm2'} );
  end 
  
  d = 10;
end

end

function plot_average(g_fs, labels, mask, params)

% fcats = { 'session' };
fcats = {};
pcats = fcats;
gcats = { 'direction' };
xcats = {};

fig_I = findall_or_one( labels, fcats, mask );

for i = 1:numel(fig_I)
  g = g_fs(fig_I{i}, :);
  g_labels = prune( labels(fig_I{i}) );
  
  g = nanmedian( g, 2 );
  
  pl = plotlabeled.make_common();
  pl.add_points = false;
  pl.marker_size = 3;
  pl.points_are = { 'unified_filename' };
  axs = pl.bar( g, g_labels, xcats, gcats, pcats );
end

end

function plot_over_time_per_run(g_fs, sums, labels, mask, params)

fcats = { 'unified_filename' };
pcats = fcats;
gcats = { 'direction' };

fig_I = findall_or_one( labels, fcats, mask );

figure( 2 );

for i = 1:numel(fig_I)
  [p_I, p_C] = findall( labels, pcats, fig_I{i} );
  
  num_panels = numel( p_I ) * 2;
  shape = ternary( num_panels == 2, [2, 1], plotlabeled.get_subplot_shape(num_panels) );
  
  axs = gobjects( num_panels, 1 );
  
  for j = 1:numel(p_I)    
    ind1 = (j-1)*2 + 1;
    ind2 = (j-1)*2 + 2;
    
    ax1 = subplot( shape(1), shape(2), ind1 );
    ax2 = subplot( shape(1), shape(2), ind2 );
    axs(ind1:ind2) = [ax1, ax2];
    
    [g_I, g_C] = findall( labels, gcats, p_I{j} );
    mean_fs = bfw.row_nanmean( g_fs, g_I );
    mean_sums = bfw.row_nanmean( sums, g_I );
    
    for k = 1:rows(mean_fs)
      mean_fs(k, :) = bfw.zscore( mean_fs(k, :), [], 2, 'omitnan' );
    end
    
    hs = plot( ax1, 1:size(mean_fs, 2), mean_fs );
    plot( ax2, 1:size(mean_sums, 2), mean_sums );
    legend( hs, strrep(fcat.strjoin(g_C, ' | '), '_', ' ') );
    title( ax1, strrep(fcat.strjoin(p_C(:, j), ' | '), '_', ' ') );
    
    ylim( ax1, [-3, 3] );
  end
end

end

function mask = get_base_mask(labels, mask_func)
mask = mask_func( labels, rowmask(labels) );
end