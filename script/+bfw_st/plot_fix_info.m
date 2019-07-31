function plot_fix_info(fix_info_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw_st.default_config();
defaults.mask_func = @(labels) rowmask(labels);

params = bfw.parsestruct( defaults, varargin );

labels = fix_info_outs.labels';
handle_labels( labels );

calc_each = { 'roi', 'unified_filename', 'stim_type', 'stim_id', 'looks_by' };
[run_labels, calc_I] = keepeach( labels', calc_each );

durations = bfw.row_sum( fix_info_outs.durations, calc_I );
counts = cellfun( @numel, calc_I );

mask = params.mask_func( run_labels );

plot_per_monkey( durations, run_labels', mask, 'durations', params );
plot_per_monkey( counts, run_labels', mask, 'counts', params );

plot_across_monkeys( durations, run_labels', mask, 'durations', params );
plot_across_monkeys( counts, run_labels', mask, 'counts', params );

end

function plot_across_monkeys(data, labels, mask, kind, params)

fig_cats = { 'task_type' };
xcats = { 'roi' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'region' };

plot_bars( data, labels', mask, fig_cats, xcats, gcats, pcats, kind, 'across_monkeys', params );

end

function plot_per_monkey(data, labels, mask, kind, params)

fig_cats = { 'task_type', 'id_m1' };
xcats = { 'roi' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'region', 'id_m1' };

plot_bars( data, labels', mask, fig_cats, xcats, gcats, pcats, kind, 'per_monkey', params );

end

function plot_bars(data, labels, mask, fcats, xcats, gcats, pcats, kind, subdir, params)

fig_I = findall_or_one( labels, fcats, mask );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  
  pltdat = data(fig_I{i});
  pltlabs = prune( labels(fig_I{i}) );
  
  axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );
  
  if ( params.do_save )
    save_p = bfw_st.stim_summary_plot_p( params, kind, subdir );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, pltlabs, [fcats, pcats] );
  end
end

end

function labels = handle_labels(labels)

bfw.get_region_labels( labels );
bfw.add_monk_labels( labels );

end