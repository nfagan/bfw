function plot_proportion_sig_sessions(ps, labels, varargin)

assert_ispair( ps, labels );
validateattributes( ps, {'double'}, {'vector'}, mfilename, 'ps' );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.alpha = 0.05;
params = bfw.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

plot_bars( ps, labels', mask, params );

end

function plot_bars(ps, labels, mask, params)

fcats = {};
xcats = {'roi-pairs'};
pcats = [ fcats, {'each'} ];
gcats = {'region'};

fig_I = findall_or_one( labels, fcats, mask );
for i = 1:numel(fig_I)
  pl = plotlabeled.make_common;
  
  plt = ps(fig_I{i});
  labs = prune( labels(fig_I{i}) );
  
  [prop_labs, prop_I] = keepeach( labs', [xcats, gcats, pcats, fcats] );
  p_sigs = nan( size(prop_I) );
  
  for j = 1:numel(prop_I)
    p_sigs(j) = pnz( plt(prop_I{j}) < params.alpha );
  end
  
  axs = pl.bar( p_sigs, prop_labs, xcats, gcats, pcats );
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_save_p( params );
    dsp3.req_savefig( gcf, save_p, prop_labs, [pcats, gcats, xcats, fcats] );
  end
end

end

function save_p = get_save_p(params)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir, 'proportion_sig', params.base_subdir );

end


function mask = get_base_mask(labels, func)

mask = func( labels, rowmask(labels) );

end