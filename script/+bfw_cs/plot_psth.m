function plt_labels = plot_psth(data, labels, time, varargin)

defaults = bfw.get_common_make_defaults();
defaults.mask_func = @bfw.default_mask_func;
defaults.smooth_func = @(x) x;
defaults.add_errors = true;
defaults.pcats = {};
defaults.gcats = {};
defaults.add_reward_size_regression = true;
defaults.alpha = 0.05;
defaults.panel_order = {};

params = bfw.parsestruct( defaults, varargin );

assert_ispair( data, labels );
assert( numel(time) == size(data, 2), 'Time does not correspond to data.' );

pl = plotlabeled.make_common();
pl.add_smoothing = true;
pl.smooth_func = params.smooth_func;
pl.add_errors = params.add_errors;
pl.panel_order = params.panel_order;
pl.x = time(:)';

clf( gcf );
cla( gca );

mask = params.mask_func( labels, rowmask(labels) );
plt_data = data(mask, :);
plt_labels = prune( labels(mask) );

[axs, hs, inds] = pl.lines( plt_data, plt_labels, params.gcats, params.pcats );

if ( params.add_reward_size_regression )
  reward_size_regression( plt_data, plt_labels, time, axs, inds, params );
end

end

function reward_size_regression(data, labels, t, axs, inds, params)

for i = 1:numel(axs)
  ind_set = inds{i};
  ind = cat_expanded( 1, ind_set(:) );
  level_strs = cellstr( labels, 'reward-level', ind );
  parsed = fcat.parse( level_strs, 'reward-' );
  assert( ~any(isnan(parsed)), 'Failed to parse some reward levels.' );
  
  for j = 1:size(data, 2)    
    col = data(ind, j);
    no_nans = ~isnan( col );
    col = col(no_nans);
    levels = parsed(no_nans);
    
    if ( ~isempty(col) )
      lm = fitlm( col, levels );
      p = lm.Coefficients.pValue(2);
      
      if ( p < params.alpha )
        set( axs(i), 'nextplot', 'add' );
        plot( axs(i), t(j), max(get(gca, 'ylim')), 'k*' );
      end
    end
  end
end

end