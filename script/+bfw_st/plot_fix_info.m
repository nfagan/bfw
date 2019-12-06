function plot_fix_info(fix_info_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw_st.default_config();
defaults.mask_func = @(labels) rowmask(labels);
defaults.before_plot_func = @(varargin) deal(varargin{1:nargout});
defaults.summary_func = @plotlabeled.nanmean;
defaults.fcats = {};
defaults.gcats = {};
defaults.xcats = {};
defaults.pcats = {};
defaults.points_are = {};
defaults.overlay_points = false;
defaults.separate_figs = false;
defaults.run_stats = true;

params = bfw.parsestruct( defaults, varargin );

labels = fix_info_outs.labels';
handle_labels( labels );

calc_each = { 'roi', 'unified_filename', 'stim_type', 'stim_id', 'looks_by' };
[run_labels, calc_I] = keepeach( labels', calc_each );

durations = bfw.row_sum( fix_info_outs.durations, calc_I );
counts = cellfun( @numel, calc_I );
mask = params.mask_func( run_labels );
%bfw_st.stim_amp_vs_vel

[current_dur, current_dur_labels, current_dur_mask] = get_current_duration( fix_info_outs, params );
[next_dur, next_dur_labels, next_dur_mask] = get_next_duration(fix_info_outs, params);
next_offsets = fix_info_outs.next_offsets;
current_itis = fix_info_outs.current_itis;

% per run for each day

% plot_per_run_and_day( durations, run_labels', mask, 'durations', params );
% plot_per_run_and_day( counts, run_labels', mask, 'counts', params );
% plot_per_run_and_day( current_dur, current_dur_labels, current_dur_mask, 'current_duration', params );
% plot_per_run_and_day( next_dur, next_dur_labels, next_dur_mask, 'next_duration', params );

% per day
nan_sum_params = params;
nan_sum_params.summary_func = @(x) nansum(x, 1);

% plot_per_day( current_itis, current_dur_labels, current_dur_mask, 'iti_offsets', params );
% plot_per_day( durations, run_labels', mask, 'durations', params );
% plot_per_day( ones(size(durations)), run_labels', mask, 'frequencies', nan_sum_params );
% plot_per_day( counts, run_labels', mask, 'counts', params );
% plot_per_day( current_dur, current_dur_labels, current_dur_mask, 'current_duration', params );
% plot_per_day( next_dur, next_dur_labels, next_dur_mask, 'next_duration', params );

% per monkey (across days)

plot_per_monkey( counts, run_labels', mask, 'counts', params );
% plot_per_monkey( current_itis, current_dur_labels, current_dur_mask, 'iti_offsets', params );
plot_per_monkey( durations, run_labels', mask, 'durations', params );
% plot_per_monkey( ones(size(durations)), run_labels', mask, 'frequencies', nan_sum_params );
plot_per_monkey( current_dur, current_dur_labels, current_dur_mask, 'current_duration', params );
plot_per_monkey( next_dur, next_dur_labels, next_dur_mask, 'next_duration', params );
% 
% 
% % across monkeys
% 
% plot_across_monkeys( current_itis, current_dur_labels, current_dur_mask, 'iti_offsets', params );
% plot_across_monkeys( durations, run_labels', mask, 'durations', params );
% plot_across_monkeys( ones(size(durations)), run_labels', mask, 'frequencies', nan_sum_params );
% plot_across_monkeys( counts, run_labels', mask, 'counts', params );
% plot_across_monkeys( current_dur, current_dur_labels, current_dur_mask, 'current_duration', params );
% plot_across_monkeys( next_dur, next_dur_labels, next_dur_mask, 'next_duration', params );

end

function [current_duration, current_dur_labels, mask] = get_current_duration(fix_info_out, params)

current_duration = fix_info_out.current_durations;
current_dur_labels = fix_info_out.current_duration_labels;

mask = params.mask_func( current_dur_labels );

end

function [next_duration, next_dur_labels, mask] = get_next_duration(fix_info_out, params)

next_duration = fix_info_out.next_durations;
next_dur_labels = fix_info_out.next_duration_labels;

mask = params.mask_func( next_dur_labels );

end

% function plot_per_run_and_day(data, labels, mask, kind, params)
% 
% fig_cats = { 'task_type', 'session' };
% xcats = { 'roi' };
% gcats = { 'stim_type' };
% pcats = { 'task_type', 'protocol_name', 'region', 'unified_filename' };
% 
% plot_bars( data, labels', mask, fig_cats, xcats, gcats, pcats, kind, 'per_run', params );
% 
% end

function plot_per_day(data, labels, mask, kind, params)

fig_cats = { 'session' };
xcats = { 'roi' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'region', 'session' };

plot_bars( data, labels', mask, fig_cats, xcats, gcats, pcats, kind, 'per_day', params );

end

function plot_per_monkey(data, labels, mask, kind, params)

fig_cats = { 'id_m1' };
xcats = { 'roi' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'region', 'id_m1' };

plot_bars( data, labels', mask, fig_cats, xcats, gcats, pcats, kind, 'per_monkey', params );

end

function plot_across_monkeys(data, labels, mask, kind, params)

fig_cats = { 'task_type' };
xcats = 'roi';
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'region' };

plot_bars( data, labels', mask, fig_cats, xcats, gcats, pcats, kind, 'across_monkeys', params );

end

function plot_bars(data, labels, mask, fig_cats, xcats, gcats, pcats, kind, subdir, params)

fig_cats = csunion( params.fcats, fig_cats );
fig_cats = fig_cats(:)';

mask = intersect( mask, find(~isnan(data)) );
fig_I = findall_or_one( labels, fig_cats, mask );

xcats = csunion( params.xcats, xcats );
gcats = csunion( params.gcats, gcats );
pcats = csunion( params.pcats, pcats );

xcats = xcats(:)';
gcats = gcats(:)';
pcats = pcats(:)';

spec = unique( [xcats, gcats, pcats, fig_cats] );

figs = cell( size(fig_I) );
store_plot_labels = cell( size(figs) );
all_axs = cell( size(figs) );

save_p = bfw_st.stim_summary_plot_p( params, kind, subdir );

for i = 1:numel(fig_I)  
  pl = plotlabeled.make_common();
  pl.summary_func = params.summary_func;
  pl.x_tick_rotation = 30;
  pl.add_points = params.overlay_points;
  pl.marker_size = 4;
  pl.marker_type = 'ko';
  pl.points_are = params.points_are;
  pl.connect_points = ~isempty( params.points_are );
  pl.main_line_width = 2;
  
  if ( params.separate_figs )
    pl.fig = figure(i);
  end
  
  pltdat = data(fig_I{i});
  pltlabs = prune( labels(fig_I{i}) );
  
  try
    [pltdat, pltlabs] = params.before_plot_func( pltdat, pltlabs, spec );
  catch err
    warning( 'Error in before_plot_func: \n %s', err.message );
    continue;
  end
  
  if ( isempty(pltdat) )
    warning( 'Data were empty after call to `before_plot_func`' );
    continue;
  end
  
  if ( params.run_stats )
    anovas_each = { 'task_type', 'region', 'roi', 'previous_stim_type', 'id_m1' };
    anova_factors = { 'stim_isi_quantile', 'stim_type' };
    run_anovas( pltdat, pltlabs', anovas_each, anova_factors, rowmask(pltlabs), params, save_p );
  end
  
  try    
    axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
    
    if ( isempty(params.points_are) )
      set( findall(axs, 'type', 'line'), 'color', zeros(1, 3) );
    end

    if ( params.do_save && ~params.separate_figs )
      shared_utils.plot.fullscreen( gcf );
      dsp3.req_savefig( gcf, save_p, pltlabs, [fig_cats, pcats]);
    end
    
    if ( params.separate_figs )
      figs{i} = pl.fig;
      store_plot_labels{i} = pltlabs;
      all_axs{i} = axs;
    end
  catch err
    warning( err.message );
  end
end

all_axs = vertcat( all_axs{:} );

if ( params.separate_figs && params.do_save )
  shared_utils.plot.match_ylims( all_axs );
  
  for i = 1:numel(figs)
    if ( isempty(figs{i}) )
      continue;
    end
    shared_utils.plot.fullscreen( figs{i} );
    dsp3.req_savefig( figs{i}, save_p, store_plot_labels{i}, [fig_cats, pcats]);
  end
end

end

function run_anovas(pltdat, pltlabs, anovas_each, anova_factors, mask, params, save_p)

if ( nargin < 5 )
  mask = rowmask( pltlabs );
end

anova_outs = dsp3.anovan( pltdat, pltlabs', anovas_each, anova_factors ...
  , 'mask', mask ...
  , 'remove_nonsignificant_comparisons', false ...
  , 'dimension', 2 ...
);

if ( params.do_save )
  stats_p = fullfile( save_p, 'stats' );
  dsp3.save_anova_outputs( anova_outs, stats_p, anovas_each );
end

end

function labels = handle_labels(labels)

bfw.get_region_labels( labels );
bfw.add_monk_labels( labels );

end