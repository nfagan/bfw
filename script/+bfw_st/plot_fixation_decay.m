function plot_fixation_decay(decay_outs, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw_st.default_config();
defaults.mask = rowmask( decay_outs.labels );
defaults.before_plot_func = @(varargin) deal(varargin{1:nargout});
defaults.xcats = {};
defaults.gcats = {};
defaults.pcats = {};
defaults.fcat = {};
defaults.iters = 1e3;
defaults.seed = [];
defaults.permutation_test = true;

params = bfw.parsestruct( defaults, varargin );

bounds = decay_outs.bounds;
labels = decay_outs.labels';
t = decay_outs.t;

mask = get_base_mask( labels, params.mask );

%plot_per_run_and_day (bounds, t, labels, mask, params);
plot_per_monkey( bounds, t, labels, mask, params );
% plot_per_day( bounds, t, labels, mask, params );
% plot_across_days( bounds, t, labels, mask, params );

end

% per run for each day

% function plot_per_run_and_day (bounds, t, labels, mask, params)
% 
% fig_cats = { 'task_type' ,'roi', 'session' };
% gcats = { 'stim_type' };
% pcats = { 'task_type', 'roi', 'protocol_name',  'region', 'unified_filename' };
% 
% plot_combination( bounds, t, labels', mask, fig_cats, gcats, pcats, 'per_run', params );
% 
% end

% per day

function plot_per_day(bounds, t, labels, mask, params)

fig_cats = { 'task_type', 'session' ,'roi'};
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'roi', 'region', 'session' };

plot_combination( bounds, t, labels', mask, fig_cats, gcats, pcats, 'per_day', params );

end

% per monkey

function plot_per_monkey(bounds, t, labels, mask, params)

fig_cats = { 'task_type' , 'id_m1', 'roi' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'roi', 'region', 'id_m1' };

plot_combination( bounds, t, labels', mask, fig_cats, gcats, pcats, 'per_monkey', params );

end

% across monkeys

function plot_across_days(bounds, t, labels, mask, params)

fig_cats = { 'task_type' , 'roi' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'protocol_name', 'roi', 'region' };

plot_combination( bounds, t, labels', mask, fig_cats, gcats, pcats, 'across_days', params );

end

function plot_combination(bounds, t, labels, mask, fig_cats, gcats, pcats, subdir, params)

fig_cats = csunion( params.fcat, fig_cats );

fig_I = findall_or_one( labels, fig_cats, mask );

gcats = csunion( params.gcats, gcats );
pcats = csunion( params.pcats, pcats );

gcats = gcats(:)';
pcats = pcats(:)';
fig_cats = fig_cats(:)';

spec = unique( [gcats, pcats, fig_cats] );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.x = t(1, :);
  
  pltdat = bounds(fig_I{i}, :);
  pltlabs = prune( labels(fig_I{i}) );
  
  [pltdat, pltlabs] = params.before_plot_func( pltdat, pltlabs, spec );
  
  try
    [axs, hs, inds] = pl.lines( pltdat, pltlabs, gcats, pcats );
    
    if ( params.permutation_test )
      add_compare_stats( t(1, :), pltdat, axs, hs, inds, params.iters, params.seed );
    end

    if ( params.do_save )
      save_p = bfw_st.stim_summary_plot_p( params, 'fix_decay', subdir );
      shared_utils.plot.fullscreen( gcf );
      dsp3.req_savefig( gcf, save_p, pltlabs, [fig_cats, pcats] );
    end
  catch err
    warning( err.message );
  end
end

end

function add_compare_stats(x, data, axs, hs, inds, iters, seed)

for i = 1:numel(hs)
  if ( ~isempty(seed) )
    rng_state = rng();
    rng( seed );
  end
  
  h_set = hs{i};
  ind_set = inds{i};
  ax = axs(i);
  
  if ( numel(h_set) ~= 2 )
    continue;
  end
  
  for j = 1:size(data, 2)
    real_diff = abs( nanmean(data(ind_set{1}, j) ) - nanmean(data(ind_set{2}, j)) );
    ps = zeros( iters, 1 );
    
    for k = 1:iters
      use_inds = sort( [ind_set{1}; ind_set{2}] );
      num_first = numel( ind_set{1} );
      perm_inds = use_inds(randperm(numel(use_inds)));
      
      ind1 = perm_inds(1:num_first);
      ind2 = perm_inds(num_first+1:end);
      
      data1 = data(ind1, j);
      data2 = data(ind2, j);
      
      shuff_diff = abs( nanmean(data1) - nanmean(data2) );
      ps(k) = shuff_diff >= real_diff;
    end
    
    p = sum( ps ) / iters;
    
    if ( p < 0.05 )
      hold( ax, 'on' );
      plot( ax, x(j), max(get(ax, 'ylim')), 'k*' );
    end
  end
  
  if ( ~isempty(seed) )
    rng( rng_state );
  end
end

end

function mask = get_base_mask(labels, mask)

mask = fcat.mask( labels, mask ...
  , @find, {'eyes_nf','face'} ...
);

end