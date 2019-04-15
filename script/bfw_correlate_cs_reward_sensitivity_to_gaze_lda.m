function bfw_correlate_cs_reward_sensitivity_to_gaze_lda(x, y, labels, varargin)

basic_scatter( x, y, labels );

end

function basic_scatter(x, y, labels)

figures_each = { 'region' };

gcats = { 'roi' };
pcats = { 'event-name', 'region' };

pl = plotlabeled.make_common();

fig_I = findall( labels, figures_each );

for i = 1:numel(fig_I)
  ind = fig_I{i};

  [axs, ids] = pl.scatter( x(ind), y(ind), prune(labels(ind)), gcats, pcats );
  
  d = 10;
end

end