function plot_gaze_gaze_null_performance(perf, kind, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

plot_violins( perf.performance, perf.labels', perf.params.permutation_test_iters, params );
plot_bars( perf.performance, perf.labels', perf.params.permutation_test_iters, params );

end

function plot_violins(performance, labels, perm_iters, params)

%%

[ps, p_labels] = ranksum_null_significance( performance, labels, perm_iters );

pl = plotlabeled.make_common();
pl.y_lims = [0, 1];
pl.x_tick_rotation = 30;

gcats = { 'is_permuted', 'roi' };
pcats = { 'region' };

mask = fcat.mask( labels ...
  , @find, {'is_permuted__true'} ...
);

plt_perf = performance(mask);
plt_labs = prune( labels(mask) );

axs = pl.violinalt( plt_perf, plt_labs, gcats, pcats );

if ( params.do_save )
%   save_p = get_save_p( params, 'train_gaze_test_gaze-null' );
%   shared_utils.plot.fullscreen( gcf );
%   dsp3.req_savefig( gcf, save_p, labels, [pcats, gcats] );
end

end

function plot_bars(performance, labels, perm_iters, params)

[ps, p_labels] = ranksum_null_significance( performance, labels, perm_iters );

pl = plotlabeled.make_common();
pl.y_lims = [0, 1];

xcats = { 'roi' };
gcats = { 'is_permuted' };
pcats = { 'region' };

axs = pl.bar( performance, labels, xcats, gcats, pcats );
add_sig_stars( pl, axs, ps, p_labels );
shared_utils.plot.add_horizontal_lines( axs, [0.5] );

if ( params.do_save )
  save_p = get_save_p( params, 'train_gaze_test_gaze-null' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, labels, [pcats, gcats] );
end

end

function add_sig_stars(pl, axs, ps, p_labels)

for i = 1:numel(axs)
  ax = axs(i);
  
  x_labs = strrep( get(ax, 'xticklabel'), ' ', '_' );
  x_tick = get( ax, 'xtick' );
  title_labs = char( strrep(get(get(ax, 'title'), 'string'), ' ', ' ') );
  title_labs = strtrim( strsplit(title_labs, pl.join_pattern) );
  
  for j = 1:numel(x_labs)
    p_ind = find( p_labels, [x_labs(j), title_labs(:)'] );
    assert( numel(p_ind) == 1, 'Expected 1 match for "%s".', x_labs{j} );
    
    if ( ps(p_ind) < 0.05 )
      hold( ax, 'on' );
      lims = get( ax, 'ylim' );
      plot( ax, x_tick(j), lims(2), 'k*' );
    end
  end
end

end

function [ps, summary_labels] = ranksum_null_significance(performance, labels, perm_iters)

assert_ispair( performance, labels );

[summary_labels, each_I] = keepeach( labels', {'roi', 'region'} );
ps = nan( numel(each_I), 1 );

for i = 1:numel(each_I)
  real_ind = find( labels, 'is_permuted__false', each_I{i} );
  shuff_ind = find( labels, 'is_permuted__true', each_I{i} );
  
  assert( numel(shuff_ind) / numel(real_ind) == perm_iters ...
    , 'Shuffled data do not correspond to given number of permutation test iterations.'  );
  
  ps(i) = ranksum( performance(real_ind), performance(shuff_ind) );
end

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda', dsp3.datedir ...
  , varargin{:}, params.base_subdir );

end