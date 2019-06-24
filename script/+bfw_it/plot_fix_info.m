function plot_fix_info(fix_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

labels = fix_outs.labels';

handle_labels( labels );
mask = get_base_mask( labels );

total_dur = fix_outs.fix_info(:, 2);

plot_over_runs( total_dur, labels', mask, 'total_duration', params );

end

function plot_over_runs(data, labels, mask, kind, params)

import shared_utils.plot.label_str;

assert_ispair( data, labels );
assert( isvector(data) );

figs_each = { 'session' };
fig_I = findall( labels, figs_each, mask );

for i = 1:numel(fig_I)
  fig = gcf();
  clf( fig );
  
  fig_ind = fig_I{i};
  
  pl = plotlabeled.make_common();
  pl.fig = fig;
  
  run_number_strs = combs( labels, 'run_number', fig_ind );
  run_nums = bfw_it.parse_run_numbers( run_number_strs );
  [~, sorted_I] = sort( run_nums );
  
  pl.panel_order = run_number_strs(sorted_I);
  
  xcats = { 'run_number' };
  pcats = { 'region', 'session', 'stim_frequency' };
  gcats = { 'stim_type' };
  
  pltdat = data(fig_ind);
  pltlabs = prune( labels(fig_ind) );
  
  axs = pl.errorbar( pltdat, pltlabs, xcats, gcats, pcats );
  
  ylabel( axs(1), label_str(kind) );
  
  if ( params.do_save )
    save_p = get_save_p( params, kind );
    shared_utils.plot.fullscreen( fig );
    dsp3.req_savefig( fig, save_p, pltlabs, [pcats, figs_each] );
  end
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'stim_fix_info' ...
  , dsp3.datedir, params.base_subdir, varargin{:} );

end

function labs = handle_labels(labs)

bfw_it.decompose_image_id_labels( labs );
bfw_it.add_run_number( labs );

end

function mask = get_base_mask(labs)

mask = bfw_it.find_non_error_runs( labs );

end