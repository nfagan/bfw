function plot_reward_gaze_significant_cell_info(gaze_labels, reward_labels, all_labels, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.gaze_mask_func = @(labels, mask) mask;
defaults.reward_mask_func = @(labels, mask) mask;
defaults.all_mask_func = @(labels, mask) mask;
defaults.prefix = '';
defaults.venn_percent = false;

params = bfw.parsestruct( defaults, varargin );

%%

gaze_mask = params.gaze_mask_func( gaze_labels, fcat.mask(gaze_labels) );
reward_mask = params.reward_mask_func( reward_labels, fcat.mask(reward_labels) );
all_mask = params.all_mask_func( all_labels, fcat.mask(all_labels) );

proportion_stats( gaze_labels', gaze_mask, reward_labels', reward_mask ...
  , all_labels, all_mask, params );

venn_gaze_reward( gaze_labels', gaze_mask, reward_labels', reward_mask ...
  , all_labels, all_mask, params );

end

function proportion_stats(gaze_labels, gaze_mask, reward_labels, reward_mask ...
  , all_labels, all_mask, params)

%%

[p_labels, p_inds, p_c] = keepeach( gaze_labels', 'region', gaze_mask );
addcat( p_labels, 'kind' );
ps = zeros( numel(p_inds), 1 );
counts = zeros( numel(ps)*2, 1 );
percs = zeros( size(counts) );
count_labels = fcat();
stp = 1;

for i = 1:numel(p_inds)
  tot_n = numel( find(all_labels, p_c(:, i), all_mask) );
  reward_n = numel( find(reward_labels, p_c(:, i), reward_mask) );
  gaze_n = numel( p_inds{i} );
  
  p_reward = reward_n / tot_n;
  p_gaze = gaze_n / tot_n;
  p_hat = (reward_n + gaze_n) / (tot_n*2);
  
  z_stat = (p_reward - p_gaze) / sqrt( p_hat * (1-p_hat) * (1/tot_n + 1/tot_n) );
  ps(i) = normcdf( z_stat );
  
  for j = 1:2    
    counts(stp) = reward_n;
    counts(stp+1) = gaze_n;    
    
    percs(stp) = reward_n / tot_n;
    percs(stp+1) = gaze_n / tot_n;
    
    stp = stp + 2;
    
    append( count_labels, p_labels, i );
    setcat( count_labels, 'kind', 'reward', rows(count_labels) );
    append( count_labels, p_labels, i );
    setcat( count_labels, 'kind', 'gaze', rows(count_labels) );
  end
end

pl = plotlabeled.make_common();
axs = pl.bar( percs * 100, count_labels, 'kind', {}, {'region'} );
ylabel( axs(1), '% significant cells' );

if ( params.do_save )
  save_p = get_save_p( params, 'plots', 'bar' );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, p_labels, 'region' );
end

end

function venn_gaze_reward(gaze_labels, gaze_mask, reward_labels, reward_mask ...
  , all_labels, all_mask, params)

pl = plotlabeled.make_common();

fcats = {};
pcats = { 'region' };

intersect_cats = { 'region', 'session', 'unit_uuid' };

sig_gaze_reward = bfw.fcat_intersect( gaze_labels, reward_labels, intersect_cats ...
  , gaze_mask, reward_mask );

fig_inds = findall_or_one( gaze_labels, {}, gaze_mask );
all_axs = cell( numel(fig_inds), 1 );
figs = gobjects( numel(fig_inds), 1 );

marked_reward = false( rows(reward_labels), 1 );

for i = 1:numel(fig_inds)
  f = figure(i);
  clf( f );
  figs(i) = f;
  
  [p_inds, p_c] = findall( gaze_labels, pcats, fig_inds{i} );
  axs = gobjects( numel(p_inds), 1 );
  
  for j = 1:numel(p_inds)
    p_combs = p_c(:, j);
    p_labels = strjoin( p_combs, pl.join_pattern );
    shape = shared_utils.plot.get_subplot_shape( numel(p_inds) );
    ax = subplot( shape(1), shape(2), j );
    
    reward_ind = find( reward_labels, p_combs, reward_mask );
    shared_ind = find( sig_gaze_reward, p_combs );
    
    marked_reward(reward_ind) = true;
    
    num_gaze = numel( p_inds{j} );
    num_reward = numel( reward_ind );
    num_shared = numel( shared_ind );
    
    if ( params.venn_percent )
      num_all = numel( find(all_labels, p_combs, all_mask) );
      num_gaze = num_gaze / num_all;
      num_reward = num_reward / num_all;
      num_shared = num_shared / num_all;
    end
    
    [h, info] = venn( [num_gaze, num_reward], num_shared );
    title( ax, p_labels );
    axs(j) = ax;
    
    if ( params.venn_percent )
      to_string = @(num) sprintf( '%0.2f', num*100 );
    else
      to_string = @num2str;
    end
    
    num_strs = arrayfun( to_string, [num_gaze, num_reward, num_shared], 'un', 0 );
    
    for k = 1:numel(num_strs)
      text( axs(j), info.ZoneCentroid(k, 1), info.ZoneCentroid(k, 2), num_strs{k} );
    end
  end
  
  if ( numel(axs) > 0 )
    legend( {'gaze', 'reward'} );
  end
  
  all_axs{i} = axs;
end

all_axs = vertcat( all_axs{:} );
shared_utils.plot.match_xlims( all_axs );
shared_utils.plot.match_ylims( all_axs );

if ( params.do_save )
  save_p = get_save_p( params, 'plots', 'venn' );
  
  for i = 1:numel(fig_inds)
    shared_utils.plot.fullscreen( figs(i) );    
    dsp3.req_savefig( figs(i), save_p, prune(gaze_labels(fig_inds{i})) ...
      , [fcats, pcats], params.prefix );
  end
end

end

function save_p = get_save_p(params, kind, varargin)

save_p = fullfile( bfw.dataroot(params.config), kind, 'cell_type_classification' ...
  , dsp3.datedir, 'significant_cell_info', params.base_subdir, varargin{:} );

end