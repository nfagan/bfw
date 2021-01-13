function plot_decoding_over_time_performance(data, labels, t, ps, p_labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.cats = {{}, {}};
defaults.p_match = { 'region' };
defaults.alpha = 0.05;
params = bfw.parsestruct( defaults, varargin );

assert_ispair( data, labels );
assert_ispair( ps, p_labels );
assert( numel(t) == size(data, 2) && numel(t) == size(ps, 2) ...
  , 'Time series do not match data.' );
validateattributes( data, {'double'}, {'2d'}, mfilename, 'data' );

%%

gcats = params.cats{1};
pcats = params.cats{2};

if ( numel(params.cats) > 2 )
  fcats = params.cats{3};
else
  fcats = {};
end

fig_I = findall_or_one( labels, fcats );

for idx = 1:numel(fig_I)
  fig_ind = fig_I{idx};
  d = data(fig_ind, :);
  l = prune( labels(fig_ind) );
  
  pl = plotlabeled.make_common();
  pl.x = t;
  [axs, all_hs, all_inds] = pl.lines( d, l, gcats, [pcats, fcats] );

  for i = 1:numel(all_hs)
    ax = axs(i);
    hold( ax, 'on' );
    hs = all_hs{i};
    inds = all_inds{i};

    for j = 1:numel(inds)
      match_c = combs( l, params.p_match, inds{j} );
      p_ind = find( p_labels, match_c );
      assert( numel(p_ind) == 1, 'More or fewer than 1 match for p-value labels.' );
      p = ps(p_ind, :);

      for k = 1:numel(p)
        if ( p(k) < params.alpha )
          plot( ax, t(k), max(get(ax, 'ylim')), 'k*' );
        end
      end
    end  
  end

  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = fullfile( bfw.dataroot(params.config), 'plots/lda/over_time', dsp3.datedir );
    dsp3.req_savefig( gcf, save_p, l, [fcats, gcats, pcats], params.prefix );
  end
end

end