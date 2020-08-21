function plot_accuracy(perf, labels, varargin)

assert_ispair( perf, labels );
validateattributes( perf, {'double'}, {'vector'}, mfilename, 'perf' );

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.mask_func = @bfw.default_mask_func;
defaults.alpha = 0.05;
defaults.group_order = { 'bla', 'accg', 'ofc', 'dmpfc' };
defaults.panel_order = panel_order();
params = bfw.parsestruct( defaults, varargin );

mask = get_base_mask( labels, params.mask_func );

% violin_plot( perf, labels, mask, params );
split_violin_plot( perf, labels, mask, params );

end

function split_violin_plot(perf, labels, mask, params)

fcats = {};
pcats = [ fcats, {'each', 'roi-pairs', 'looks_by'} ];
gcats = {'region'};

fig_I = findall_or_one( labels, fcats, mask );
for i = 1:numel(fig_I)
  f = gcf;
  clf( f );
  
  [subset_labs, p_I, p_C] = keepeach( labels', pcats, fig_I{i} );
  
%   order_ind = cellfun( @(x) find(strcmp(p_C(2, :), x)), params.panel_order );
%   subset_labs = subset_labs(order_ind);
%   p_I = p_I(order_ind);
%   p_C = p_C(:, order_ind);
  
  axs = gobjects( size(p_I) );
  shape = plotlabeled.get_subplot_shape( numel(p_I) );
  
  for j = 1:numel(p_I)
    ax = subplot( shape(1), shape(2), j );
    [g_I, g_C] = findall( labels, gcats, p_I{j} );
    axs(j) = ax;
    
    order_ind = cellfun( @(x) find(strcmp(g_C(1, :), x)), params.group_order );
    g_I = g_I(order_ind);
    g_C = g_C(:, order_ind);
  
    for k = 1:numel(g_I)
      plt = perf(g_I{k}, :);
      labs = prune( labels(g_I{k}) );

      real_mask = find( labs, 'real' );
      null_mask = find( labs, 'null' );

      assert( numel(real_mask) == numel(null_mask), ['Expected matching subsets' ...
        , ' for real and null distributions.'] );

      real_dat = plt(real_mask);
      null_dat = plt(null_mask);
      h1_color = [1, 1, 0];
      h2_color = [0, 1, 1];

      h1 = distributionPlot( ax, real_dat ...
        , 'histOri', 'left' ...
        , 'widthDiv', [2, 1] ...
        , 'color', h1_color ...
        , 'xValues', k ...
        , 'xMode', 'manual' ...
      );
      h2 = distributionPlot( ax, null_dat ...
        , 'histOri', 'right' ...
        , 'widthDiv', [2, 2] ...
        , 'color', h2_color ...
        , 'xValues', k ...
        , 'xMode', 'manual' ...
      );
    
      leg_h1_h = h1{2}(1);
      leg_h2_h = h2{2}(1);
      set( leg_h1_h, 'color', h2_color ); % inverted
      set( leg_h2_h, 'color', h1_color );
      
      legend( [leg_h1_h, leg_h2_h], {'null', 'real'} );
    
      real_mean = nanmean( real_dat );
      is_sig = pnz( real_mean < null_dat ) <= params.alpha;
      
      if ( is_sig )
        hold( ax, 'on' );
        plot( ax, k, max(get(ax, 'ylim')), 'k*', 'markersize', 6 );
      end
    end
    
    set( ax, 'xtick', 1:(numel(g_I)) );
    set( ax, 'xticklabels', fcat.strjoin(g_C, ' | ') );
    title( ax, strrep(strjoin(p_C(:, j), ' | '), '_', ' ') );
  end
  
  shared_utils.plot.match_ylims( axs );

  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_save_p( params );
    dsp3.req_savefig( gcf, save_p, subset_labs, pcats );
  end
end

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
  
  null_plt = plt(null_mask);
  null_labs = labs(null_mask);
  
  [axs, inds] = pl.violinalt( null_plt, null_labs, gcats, pcats );
  for j = 1:numel(inds)
    for k = 1:numel(inds{j})
      cs = combs( null_labs, [gcats, pcats], inds{j}{k} );
      match_ind = find( labs, cs, real_mask );
      real_subset = plt(match_ind);
      null_subset = null_plt(inds{j}{k});
      
      real_mean = mean( real_subset );
      
      ax = axs(j);
      hold( ax, 'on' );
      null_h = plot( ax, k, real_mean, 'o', 'markersize', 4, 'linewidth', 2 );
      is_sig = pnz( real_mean < null_subset ) <= params.alpha;
      legend( null_h, 'real mean' );
      
      if ( is_sig )
        plot( ax, k, max(get(ax, 'ylim')), 'k*', 'markersize', 6 );
      end
    end
  end
  
  if ( params.do_save )
    shared_utils.plot.fullscreen( gcf );
    save_p = get_save_p( params );
    dsp3.req_savefig( gcf, save_p, null_labs, pcats );
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

function order = panel_order()

order = { 'whole_face v. nonsocial_object' ...
  , 'eyes_nf v. face' ...
  , 'eyes_nf v. nonsocial_object' };

end