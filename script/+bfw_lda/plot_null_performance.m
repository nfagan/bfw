function plot_null_performance(perf, kind, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.separate_figures_for_event_name = true;
params = bfw.parsestruct( defaults, varargin );

pop_iters = perf.params.n_iters;

% plot_bars( perf.performance, perf.labels', perf.params.permutation_test_iters, kind, params );
plot_violins( perf.performance, perf.labels', pop_iters, perf.params.permutation_test_iters, kind, params );

end

function plot_violins(performance, labels, pop_iters, perm_iters, kind, params)

fcats = keep_specifiers_for_kind( {'region', 'event-name'}, kind );
gcats = keep_specifiers_for_kind( {'roi', 'reward-level'}, kind );
pcats = keep_specifiers_for_kind( {'region', 'event-name'}, kind );
null_each = keep_specifiers_for_kind( {'region', 'roi', 'reward-level', 'event-name'}, kind );

if ( ~params.separate_figures_for_event_name )
  fcats = setdiff( fcats, 'event-name' );
end

spec = [ gcats, pcats, fcats, null_each ];
addcat( labels, spec );

[ps, p_labels] = ranksum_null_significance( performance, labels, perm_iters, null_each );

pl = plotlabeled.make_common();
pl.y_lims = [];

addcat( labels, [gcats, pcats, fcats] );

mask = fcat.mask( labels ...
  , @find, 'is_permuted__false' ...
);

expect_num_null = perm_iters;
% plot_func = @violinalt;
plot_func = @boxplot;

post_plot_func = @(varargin) post_plot_violin(varargin, performance, labels, expect_num_null, ps, p_labels);
save_p = get_save_p( params, sprintf('%s-null', kind), 'violin' );
plot_figs( pl, plot_func, post_plot_func, fcats, performance, labels', mask ...
  , {gcats, pcats}, save_p, params );

end

function plot_bars(performance, labels, perm_iters, kind, params)

fcats = {};
xcats = { 'roi', 'reward-level' };
gcats = { 'is_permuted' };
pcats = { 'region' };
null_each = { 'region', 'roi', 'reward-level' };

spec = [ xcats, gcats, pcats, fcats ];
addcat( labels, spec );

null_each = keep_specifiers_for_kind( null_each, kind );
xcats = keep_specifiers_for_kind( xcats, kind );
gcats = keep_specifiers_for_kind( gcats, kind );
pcats = keep_specifiers_for_kind( pcats, kind );

[ps, p_labels] = ranksum_null_significance( performance, labels, perm_iters, null_each );

pl = plotlabeled.make_common();
pl.y_lims = [0, 1];

mask = fcat.mask( labels );

post_plot_func = @(pl, varargin) post_plot_bar( pl, varargin{:}, ps, p_labels' );

save_p = get_save_p( params, sprintf('%s-null', kind), 'bar' );
plot_figs( pl, @bar, post_plot_func, fcats, performance, labels', mask ...
  , {xcats, gcats, pcats}, save_p, params );

end

function spec = keep_specifiers_for_kind(spec, kind)

switch ( kind )
  case 'train_gaze_test_gaze'
    spec = setdiff( spec, {'reward-level', 'event-name'} );
  case 'train_reward_test_reward'
    spec = setdiff( spec, 'roi' );
  case {'train_reward_test_gaze', 'train_gaze_test_reward'}
    %
  otherwise
    error( 'Unrecognized kind "%s".', kind );
end

end

function post_plot_violin(plot_inputs, data, labels, expect_num, ps, p_labels)

axs = plot_inputs{3};

xtickangle( axs, 30 );
shared_utils.plot.match_ylims( axs );
overlay_null_means_and_ps( axs, data, labels, expect_num, ps, p_labels );

end

function selectors = labels_to_selectors(labels)
labels = eachcell( @(x) strsplit(x, ' | '), labels );
selectors = eachcell( @(x) strrep(x, ' ', '_'), labels );  
end

function overlay_null_means_and_ps(axs, data, labels, expect_num, ps, p_labels)

for i = 1:numel(axs)
  ax = axs(i);
  
  x_selectors = labels_to_selectors( get(ax, 'xticklabels') );
  title_selectors = labels_to_selectors( get(get(ax, 'title'), 'string') );
  title_selectors = title_selectors{1};
  
  x_ticks = get( ax, 'xtick' );
  
  for j = 1:numel(x_selectors)
    perm_selectors = [ x_selectors{j}, title_selectors, {'is_permuted__true'} ];
    real_selectors = perm_selectors;
    real_selectors{end} = 'is_permuted__false';
    
    data_ind = find( labels, perm_selectors );
    real_ind = find( labels, real_selectors );
    
    if ( numel(data_ind) / numel(real_ind) ~= expect_num )
      error( 'Expected %d matches for "%s"; got %d', expect_num, strjoin(perm_selectors), numel(data_ind) );
    end
    
    p_ind = find( p_labels, real_selectors(1:end-1) );
    if ( numel(p_ind) ~= 1 )
      error( 'Expected 1 match for "%s".', strjoin(real_selectors(1:end-1)) );
    end
    
    mean_null = mean( data(data_ind) );
    hold( ax, 'on' );
    plot( ax, x_ticks(j), mean_null, 'ko' );
    
    if ( ps(p_ind) < 0.05 )
      plot( ax, x_ticks(j), max(get(ax, 'ylim')), 'k*' );
    end
  end
end

end

function post_plot_bar(pl, figs, axs, inds, data, labels, ps, ps_labels)

add_sig_stars( pl, axs, ps, ps_labels );
shared_utils.plot.add_horizontal_lines( axs, 0.5 );

end

function plot_figs(pl, plot_func, post_plot_func, fcats, data, labels, mask, spec, save_p, params)

plt_data = data(mask);
plt_labels = prune( labels(mask) );

[figs, axs, inds] = pl.figures( plot_func, plt_data, plt_labels, fcats, spec{:} );
post_plot_func( pl, figs, axs, inds, plt_data, plt_labels );

if ( params.do_save )  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs(i) );
    dsp3.req_savefig( figs(i), save_p, prune(plt_labels(inds{i})), horzcat(spec{:}) );
  end
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

function [ps, summary_labels] = ranksum_null_significance(performance, labels, perm_iters, each)

assert_ispair( performance, labels );

[summary_labels, each_I] = keepeach( labels', each );
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