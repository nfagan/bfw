function plot_accuracy(perf, labels, varargin)

assert_ispair( perf, labels );
validateattributes( perf, {'double'}, {'vector'}, mfilename, 'perf' );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.alpha = 0.05;
params = bfw.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

violin_plot( perf, labels, mask, params );

end

function violin_plot(perf, labels, mask, params)

fcats = {};
pcats = [ fcats, {'each', 'roi-pairs'} ];
gcats = {'region'};

fig_I = findall_or_one( labels, fcats, mask );
for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  
  plt = perf(fig_I{i}, :);
  labs = prune( labels(fig_I{i}) );
  
  real_mask = find( labs, 'real' );
  null_mask = find( labs, 'null' );
  
  real_plt = plt(real_mask);
  real_labs = labs(real_mask);
  
  [axs, inds] = pl.violinalt( real_plt, real_labs, gcats, pcats );
  for j = 1:numel(inds)
    for k = 1:numel(inds{j})
      cs = combs( real_labs, [gcats, pcats], inds{j}{k} );
      match_ind = find( labs, cs, null_mask );
      null_subset = plt(match_ind);
      null_mean = mean( null_subset );
      real_mean = mean( real_plt(inds{j}{k}) );
      ax = axs(j);
      hold( ax, 'on' );
      null_h = plot( ax, k, null_mean, 'o', 'markersize', 2 );
      is_sig = (1 - pnz(real_mean > null_subset)) <= params.alpha;
      legend( null_h, 'null mean' );
      
      if ( is_sig )
        plot( ax, k, max(get(ax, 'ylim')), 'k*', 'markersize', 4 );
      end
    end
  end
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_save_p( params );
    dsp3.req_savefig( gcf, save_p, real_labs, pcats );
  end
end

end

function save_p = get_save_p(params)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir, 'average_accuracy', params.base_subdir );

end

function mask = get_base_mask(labels, func)

mask = func( labels, rowmask(labels) );

end