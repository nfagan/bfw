gaze_counts_file = '/Users/Nick/Downloads/gaze_counts.mat';
rwd_counts_file = '/Users/Nick/Downloads/reward_counts.mat';

gaze_counts = shared_utils.io.fload( gaze_counts_file );
rwd_counts = shared_utils.io.fload( rwd_counts_file );

%
% Use whole right object for nonsocial_object

%%

shared_ids = bfw_lda.shared_unit_ids( gaze_counts.labels, rwd_counts.labels );

%%

num_units = size( shared_ids, 2 );

classify_params = struct();
classify_params.seed = 0;

gaze_t_ind = gaze_counts.t >= 0 & gaze_counts.t <= 0.3;
select_gaze_spikes = nanmean( gaze_counts.spikes(:, gaze_t_ind), 2 );

[rwd_t_windows, rwd_event_names] = bfw_lda.reward_time_windows();

rwd_base_mask = fcat.mask( rwd_counts.labels ...
  , @find, rwd_event_names ...
  , @findnone, 'reward-NaN' ...
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
    gaze_ind = find( gaze_counts.labels, unit_selectors );
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

x = accuracies(:, 1);
y = accuracies(:, 2);
scatter_labels = accuracy_labels';

fcats = { 'region' };
gcats = {};
pcats = { 'event-name' };
pcats = union( pcats, fcats );

fig_I = findall_or_one( scatter_labels, fcats );

for i = 1:numel(fig_I)
pl = plotlabeled.make_common();
pl.fig = figure(i);
pl.marker_size = 10;

ind = fig_I{i};
x_ = x(ind);
y_ = y(ind);
labs = prune( scatter_labels(ind) );

[axs, ids] = pl.scatter( x_, y_, labs, gcats, pcats );
plotlabeled.scatter_addcorr( ids, x_, y_ );

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


