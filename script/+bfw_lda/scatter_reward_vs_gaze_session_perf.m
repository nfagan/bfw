function scatter_reward_vs_gaze_session_perf(perf, labels, varargin)

assert_ispair( perf, labels );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.each = { 'data-type', 'comb-uuid' };

params = bfw.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

plot_scatter( perf, labels', mask, params );

end

function plot_scatter(perf, labels, mask, params)

[each_labs, each_I] = keepeach( labels', params.each, mask );
each_perf = bfw.row_nanmean( perf, each_I );

fcats = {'data-type'};
pcats = [ fcats, {'region', 'each', 'roi-pairs'} ];
gcats = {};

fig_I = findall_or_one( each_labs, fcats );
for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.marker_size = 4;
  
  plt = each_perf(fig_I{i}, :);
  labs = prune( each_labs(fig_I{i}) );
  
  [axs, ids] = pl.scatter( plt(:, 1), plt(:, 2), labs, gcats, pcats );
  hs = plotlabeled.scatter_addcorr( ids, plt(:, 1), plt(:, 2) );
  xlabel( axs(1), 'Gaze performance' );
  ylabel( axs(1), 'Reward performance' );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_save_p( params );
    dsp3.req_savefig( gcf, save_p, labs, pcats );
  end
end

end

function save_p = get_save_p(params)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir, 'scatter_reward_vs_gaze_session', params.base_subdir );

end

function mask = get_base_mask(labels, func)

mask = func( labels, rowmask(labels) );

end