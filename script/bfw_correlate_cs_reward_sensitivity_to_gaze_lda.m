function bfw_correlate_cs_reward_sensitivity_to_gaze_lda(x, y, labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask = rowmask( labels );

params = bfw.parsestruct( defaults, varargin );

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir );

basic_scatter( x, y, labels, plot_p, params );

end

function basic_scatter(x, y, labels, plot_p, params)

figures_each = { 'region' };

gcats = { 'event-name' };
pcats = { 'roi', 'region', 'shuffled-type' };

pl = plotlabeled.make_common();

fig_I = findall( labels, figures_each, params.mask );

all_stats = [];
stat_labs = fcat();

for i = 1:numel(fig_I)
  ind = fig_I{i};
  
  use_x = x(ind);
  use_y = y(ind);
  use_labs = prune( labels(ind) );

  [axs, ids] = pl.scatter( use_x, use_y, use_labs, gcats, pcats );
  [h, stats] = pl.scatter_addcorr( ids, use_x, use_y );
  
  xlabel( axs(1), 'Reward sensitivity' );
  ylabel( axs(1), 'Gaze sensitivity' );
  
  all_stats = [ all_stats; [stats, stats(:, end) < 0.05] ];
  
  for j = 1:numel(ids)
    append1( stat_labs, use_labs, ids(j).index );
  end
  
  if ( params.do_save )
    save_p = fullfile( plot_p, params.base_subdir );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, use_labs, pcats );
  end
end

if ( params.do_save )
  save_p = fullfile( plot_p, params.base_subdir );
  
  plot_spec = unique( cshorzcat(gcats, pcats, figures_each) );
  
  col_labs = fcat.create( 'measure', {'r', 'p', 'significant'} );
  row_labs = rmcat( stat_labs', setdiff(getcats(stat_labs), plot_spec) );
  
  all_tbl = fcat.table( all_stats, row_labs, col_labs );
  only_sig_tbl = all_tbl(all_stats(:, end) == 1, :);
  
  dsp3.req_writetable( all_tbl, save_p, stat_labs, plot_spec, 'all' );
  dsp3.req_writetable( only_sig_tbl, save_p, stat_labs, plot_spec, 'only_significant' );
end

end