gaze_mask_func = @(l, m) fcat.mask(l, m ...
  , @find, {'face', 'eyes_nf', 'nonsocial_object'} ...
  , @find, 'm1' ...
);

rwd_mask_func = @(l, m) fcat.mask(l, m ...
  , @findnone, 'reward-NaN' ...
  , @find, 'no-error' ...
);

[inds, labs] = ...
  bfw_lda.find_shared_unit_ids( gaze_counts.labels, rwd_counts.labels ...
  , gaze_mask_func, rwd_mask_func ...
);

%%

gaze_win = [ 0, 0.3 ];
gaze_t = gaze_counts.t;
gaze_ts = gaze_counts.spikes;

[rwd_windows, rwd_window_names] = bfw_lda.reward_time_windows;
rwd_ts = rwd_counts.psth;
rwd_t = rwd_counts.t;

select_spikes = @(spikes, t, t_win) spikes(:, mask_gele(t, t_win(1), t_win(2)));
spike_func = @(x) nanmean( x, 2 );

gaze_ts = spike_func( select_spikes(gaze_ts, gaze_t, gaze_win) );
all_rwd_ts = nan( rows(rwd_ts), 1 );

for i = 1:numel(rwd_window_names)
  rwd_ind = find( rwd_counts.labels, rwd_window_names{i} );
  spikes = select_spikes(rwd_ts, rwd_t, rwd_windows{i});
  sub_ts = spike_func( spikes );
  all_rwd_ts(rwd_ind) = sub_ts(rwd_ind);
end

%%

mean_ts = [];
mean_labs = fcat();
% mean_func = @(x) nanmean(x);
mean_func = @(x) 1 - pnz(x);

for i = 1:numel(inds)
  gaze_ind = inds{i}{1};
  rwd_ind = inds{i}{2};
  
  gaze_mean_ts = mean_func( gaze_ts(gaze_ind) );
  rwd_I = findall( rwd_counts.labels, 'event-name', rwd_ind );
  gaze_l = prune( append1(fcat, gaze_counts.labels, gaze_ind) );
  
  for j = 1:numel(rwd_I)
    rwd_mean_ts = mean_func( rwd_ts(rwd_I{j}) );
    
    rwd_l = prune( append1(fcat, rwd_counts.labels, rwd_I{j}) );
    join( rwd_l, gaze_l );
    
    mean_ts(end+1, :) = [rwd_mean_ts, gaze_mean_ts];
    append( mean_labs, rwd_l );
  end
end

assert_ispair( mean_ts, mean_labs );

%%

pcats = { 'region', 'event-name' };
gcats = {};

plt_data = mean_ts;
plt_labs = mean_labs';

mask = find( plt_labs, 'accg' );
plt_data = plt_data(mask, :);
plt_labs = prune( plt_labs(mask) );

pl = plotlabeled.make_common;
pl.marker_size = 4;
[axs, ids] = pl.scatter( plt_data(:, 1), plt_data(:, 2), plt_labs, gcats, pcats );
shared_utils.plot.xlabel( axs, 'Reward' );
shared_utils.plot.ylabel( axs, 'Gaze' );

%%

pcats = { 'region', 'event-name' };

plt_data = mean_ts;
plt_labs = mean_labs';

num_devs = 1.2;
use_col = 1;
ax_label = ternary( use_col == 1, 'Reward', 'Gaze' );

mask = fcat.mask( plt_labs ...
  , @find, 'cs_reward' ...
);

plt_data = plt_data(mask, :);
plt_labs = prune( plt_labs(mask) );

pl = plotlabeled.make_common;
pl.marker_size = 4;
[axs, hist_inds] = pl.hist( plt_data(:, use_col), plt_labs, pcats, 20 );
shared_utils.plot.xlabel( axs, ax_label );

for i = 1:numel(hist_inds)
  sub_data = plt_data(hist_inds{i}, use_col);
  med = median( sub_data );
  minus_dev = nanmean( sub_data ) - nanstd( sub_data ) * num_devs;
  
  shared_utils.plot.hold( axs(i), 'on' );
  shared_utils.plot.add_vertical_lines( axs(i), med );
  shared_utils.plot.add_vertical_lines( axs(i), nanmean(sub_data), 'b--' );
  shared_utils.plot.add_vertical_lines( axs(i), minus_dev, 'r--' );
  shared_utils.plot.set_xlims( axs(i), [-0.5, 1.5] );
  
  med_str = sprintf( 'Med = %0.2f', med );
  minus_dev_str = sprintf( '%0.2f', minus_dev );
  
  text( axs(i), minus_dev, max(get(axs(i), 'ylim')), minus_dev_str );
  text( axs(i), med, max(get(axs(i), 'ylim')), med_str );
end

%%

thresholds = [0.1, 0.2, 0.3, 0.4];
thresh_labels = arrayfun( @(x) sprintf('threshold-%0.2f', x), thresholds, 'un', 0 );

plt_data = mean_ts;
plt_labs = mean_labs';

num_devs = 1.2;
use_col = 1;
ax_label = ternary( use_col == 1, 'Reward', 'Gaze' );

mask = fcat.mask( plt_labs ...
  , @find, {'cs_reward', 'cs_target_acquire', 'cs_delay'} ...
);

plt_data = plt_data(mask, use_col); 
plt_labs = prune( plt_labs(mask) );

[tmp_labs, each_I] = keepeach( plt_labs', {'region', 'event-name'} );
prop_labs = fcat();
ps = [];

for i = 1:numel(each_I)
  for j = 1:numel(thresholds)
    p_sub = pnz( plt_data(each_I{i}) <= thresholds(j) );
    ps(end+1, 1) = p_sub;
    addsetcat( tmp_labs, 'threshold', thresh_labels{j} );
    append( prop_labs, tmp_labs, i );
  end
end

pl = plotlabeled.make_common();
pl.group_order = thresh_labels;

axs = pl.bar( ps, prop_labs, {'region'}, {'threshold'}, {'event-name'} );
shared_utils.plot.xlabel( axs, ax_label );

%%

shared_utils.plot.set_xlims( axs, [0, 0.5] );
shared_utils.plot.set_ylims( axs, [0, 0.5] );