% @T import base

conf = bfw.set_dataroot( '/Users/Nick/Desktop/bfw' );
base_counts_p = fullfile( bfw.dataroot(conf), 'analyses/spike_lda/reward_gaze_spikes_tree' );

% counts_p = fullfile( base_counts_p, 'counts' );
counts_p = fullfile( base_counts_p, 'counts_right_object_only' );

gaze_counts_file = fullfile( counts_p, 'gaze_counts.mat' );
rwd_counts_file = fullfile( counts_p, 'reward_counts.mat' );

gaze_counts = shared_utils.io.fload( gaze_counts_file );
rwd_counts = shared_utils.io.fload( rwd_counts_file );
replace( rwd_counts.labels, 'acc', 'accg' );

%%

outs = bfw_lda.bagged_trees_classifier( gaze_counts, rwd_counts ...
  , 'permutation_test_iters', 100 ...
  , 'permutation_test', true ...
  , 'reward_time_windows', 'cs_reward' ...
  , 'spike_criterion_func', @(varargin) bfw_lda.pnz_spike_criterion(varargin{:}, 0.3) ...
);

%%

shared_ids = bfw_lda.shared_unit_ids( gaze_counts.labels, rwd_counts.labels );

%%

num_units = size( shared_ids, 2 );

classify_params = struct();
classify_params.seed = 0;

gaze_t_ind = gaze_counts.t >= 0 & gaze_counts.t <= 0.3;
select_gaze_spikes = nanmean( gaze_counts.spikes(:, gaze_t_ind), 2 );

[rwd_t_windows, rwd_event_names] = bfw_lda.reward_time_windows();
% keep_ind = ismember( rwd_event_names, 'cs_target_acquire' );
keep_ind = true( size(rwd_event_names) );

rwd_t_windows = rwd_t_windows(keep_ind);
rwd_event_names = rwd_event_names(keep_ind);

rwd_base_mask = fcat.mask( rwd_counts.labels ...
  , @find, rwd_event_names ...
  , @findnone, 'reward-NaN' ...
);

gaze_base_mask = fcat.mask( gaze_counts.labels ...
  , @find, {'face', 'eyes_nf'} ...
);

rwd_I = cellfun( @(x) find(rwd_counts.labels, x, rwd_base_mask), rwd_event_names, 'un', 0 );

accuracies = [];
accuracy_labels = fcat();

for idx = 1:numel(rwd_I)
  shared_utils.general.progress( idx, numel(rwd_I) );
  
  rwd_each_ind = rwd_I{idx};
  rwd_t_win = rwd_t_windows{idx};
  rwd_t_ind = rwd_counts.t >= rwd_t_win(1) & rwd_counts.t <= rwd_t_win(2);
  select_rwd_spikes = nanmean( rwd_counts.psth(:, rwd_t_ind), 2 );
  
  tmp_accuracies = cell( num_units, 1 );
  tmp_labels = cell( size(tmp_accuracies) );

  parfor i = 1:num_units
    unit_selectors = shared_ids(:, i);
    gaze_ind = find( gaze_counts.labels, unit_selectors, gaze_base_mask );
    rwd_ind = find( rwd_counts.labels, unit_selectors, rwd_each_ind );

    if ( isempty(gaze_ind) )
      gaze_accuracy = nan;
    else
      [~, gaze_accuracy] = bfw_lda.bagged_trees_vector_spike_classifier( ...
        select_gaze_spikes, gaze_counts.labels, 'roi', gaze_ind, classify_params );
    end

    if ( isempty(rwd_ind) )
      rwd_accuracy = nan;
    else
      [~, rwd_accuracy] = bfw_lda.bagged_trees_vector_spike_classifier( ...
        select_rwd_spikes, rwd_counts.labels, 'reward-level', rwd_ind, classify_params );
    end
    
    if ( ~isempty(rwd_ind) && ~isempty(gaze_ind) )
      tmp_gaze_labs = append1( fcat, gaze_counts.labels, gaze_ind );
      tmp_rwd_labs = append1( fcat, rwd_counts.labels, rwd_ind );
      join( tmp_gaze_labs, tmp_rwd_labs );

      tmp_labels{i} = tmp_gaze_labs;
      tmp_accuracies{i} = [gaze_accuracy, rwd_accuracy];
    end
  end
  
  non_empties = ~cellfun( @isempty, tmp_labels );
  
  append( accuracy_labels, vertcat(fcat, tmp_labels{non_empties}) );
  accuracies = [ accuracies; vertcat(tmp_accuracies{non_empties}) ];
end

%%

load( '~/Desktop/bfw/analyses/spike_lda/reward_gaze_spikes_tree/performance/perf.mat' );

%%

do_save = true;
per_session = true;
base_subdir = 'eyes-face-object';

x = accuracies(:, 1);
y = accuracies(:, 2);
scatter_labels = accuracy_labels';

fcats = { 'region' };
gcats = {};
pcats = { 'event-name' };
pcats = union( pcats, fcats );

if ( per_session )
  gcats{end+1} = 'session';
end

mask = fcat.mask( scatter_labels );

fig_I = findall_or_one( scatter_labels, fcats, mask );

all_axs = cell( size(fig_I) );
figs = cell( size(all_axs) );
plt_labs = cell( size(all_axs) );

plot_spec = unique( [fcats, gcats, pcats] );

for i = 1:numel(fig_I)
  
figs{i} = figure( i );
  
pl = plotlabeled.make_common();
pl.fig = figs{i};
pl.marker_size = 10;

ind = fig_I{i};
x_ = x(ind);
y_ = y(ind);
labs = prune( scatter_labels(ind) );

[axs, ids] = pl.scatter( x_, y_, labs, gcats, pcats );

if ( ~per_session )
  plotlabeled.scatter_addcorr( ids, x_, y_ );
end

all_axs{i} = axs;
plt_labs{i} = labs;

end

all_axs = vertcat( all_axs{:} );
shared_utils.plot.match_xlims( all_axs );
shared_utils.plot.match_ylims( all_axs );
shared_utils.plot.xlabel( all_axs, 'Gaze decoding accuracy' );
shared_utils.plot.ylabel( all_axs, 'Reward decoding accuracy' );

if ( do_save )
  session_subdir = ternary( per_session, 'per_session', 'across_sessions' );
  
  for i = 1:numel(figs)
    shared_utils.plot.fullscreen( figs{i} );
    save_p = fullfile( bfw.dataroot(conf), 'plots', 'cs_sens_vs_lda' ...
      , dsp3.datedir, base_subdir, session_subdir );
    dsp3.req_savefig( figs{i}, save_p, prune(plt_labs{i}), plot_spec );
  end
end

%%  

pl = plotlabeled.make_common();
x = accuracies(:, 2);
bar_labels = accuracy_labels';

xcats = {};
gcats = { 'event-name' };
pcats = { 'region' };

axs = pl.bar( x, bar_labels, xcats, gcats, pcats );

anova_outs = dsp3.anovan( x, bar_labels, {}, {'event-name', 'region'} );

%%

load_dir = '/Users/Nick/Desktop/performance/cs_target_acquire_spike_crit';
load_mats = shared_utils.io.findmat( load_dir, true );
loaded = eachcell( @shared_utils.io.fload, load_mats );
loaded = shared_utils.struct.soa( vertcat(loaded{:}) );

bfw_lda.recode_sig_labels( loaded.accuracy_labels, 100 );
bfw_lda.add_both_either_sig_labels( loaded.accuracy_labels );
prune( loaded.accuracy_labels );

%%

mask = fcat.mask( loaded.accuracy_labels ...
  , @find, 'real' ...
);

do_save = true;
base_subdir = '';

kinds = { {}, 'either-sig', 'both-sig', 'gaze-sig', 'rwd-sig' };
% kinds = { {} };
regions = combs( loaded.accuracy_labels, 'region', mask );

cs = dsp3.numel_combvec( kinds, regions );

for idx = 1:size(cs, 2)
  kind = kinds{cs(1, idx)};
  region = regions{cs(2, idx)};
  
  pl = plotlabeled.make_common();
  pl.marker_size = 10;

  fcats = { 'region', 'event-name' };
  pcats = csunion( fcats, [{'event-name'}, kind] );
  gcats = {};

  use_mask = intersect( mask, find(loaded.accuracy_labels, region) );
  fig_I = findall( loaded.accuracy_labels, fcats, use_mask );
  
  kind_str = ternary( isempty(char(kind)), 'any', char(kind) );

  for i = 1:numel(fig_I)
    dat = loaded.accuracies(fig_I{i}, :);
    labels = prune( loaded.accuracy_labels(fig_I{i}) );

    [axs, ids] = pl.scatter( dat(:, 1), dat(:, 2), labels, gcats, pcats );
    plotlabeled.scatter_addcorr( ids, dat(:, 1), dat(:, 2) );
    
    plot_spec = unique( [fcats, gcats, pcats] );
    
    event_name = char( combs(labels, 'event-name') );
    session_subdir = fullfile( kind_str, event_name );
    
    if ( do_save )  
      shared_utils.plot.fullscreen( gcf );
      save_p = fullfile( bfw.dataroot(conf), 'plots', 'cs_sens_vs_lda' ...
        , dsp3.datedir, base_subdir, session_subdir );
      dsp3.req_savefig( gcf, save_p, prune(labels), plot_spec );
    end
  end
end

%%  

mask = fcat.mask( loaded.accuracy_labels ...
  , @find, 'real' ...
);

kinds = { 'either-sig', 'both-sig', 'gaze-sig', 'rwd-sig' };
props_each = { 'region', 'event-name' };

props = [];
prop_labels = fcat();

for i = 1:numel(kinds)
  [tmp, tmp_labels] = ...
    proportions_of( loaded.accuracy_labels, props_each, kinds{i}, mask ); 
  addsetcat( tmp_labels, 'sig-kind', kinds{i} );
  
  true_lab_ind = find( tmp_labels, sprintf('%s-true', kinds{i}) );
  assert( ~isempty(true_lab_ind) );
  
  append( prop_labels, tmp_labels, true_lab_ind );
  props = [ props; tmp(true_lab_ind) ];
end

pl = plotlabeled.make_common();
axs = pl.bar( props, prop_labels, {'sig-kind'}, {'event-name'}, 'region' );
