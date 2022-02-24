behav_events = bfw_gather_events( ...
    'event_subdir', 'remade_032921' ...
  , 'require_stim_meta', false ...
);

%%

[I, C] = findall( behav_events.labels, 'roi' );
contains_obj = contains( C, 'nonsocial_object' );
set_ind = vertcat( I{contains_obj} );
set_to = 'nonsocial_object';
setcat( behav_events.labels, 'roi', set_to, set_ind );
behav_events = bfw.sort_events( behav_events );

%%  frequencies of n+1 events

freq_mask = find( behav_events.labels, 'm1' );
[freq_labs, each_I] = keepeach( behav_events.labels', 'unified_filename', freq_mask );
rois = combs( behav_events.labels, 'roi', findnone(behav_events.labels, 'everywhere') );
start_ts = bfw.event_column( behav_events, 'start_time' );

cat_rois = categorical( behav_events.labels, 'roi' );

freq_mats = cell( numel(each_I), 1 );
prop_mats = cell( size(freq_mats) );
for i = 1:numel(each_I)
  ei = each_I{i};
  run_starts = start_ts(ei);
  sub_rois = cat_rois(ei);
  [~, ind] = sort( run_starts );
  assert( issorted(ind) );
  
  freq_mat = zeros( numel(rois) );
  for j = 1:numel(rois)
    is_curr = sub_rois(1:end-1) == rois{j};
    for k = 1:numel(rois)
      is_next = sub_rois(2:end) == rois{k};
      freq_mat(j, k) = sum( is_curr & is_next );
    end
  end
  
  sum2 = sum( freq_mat, 2 );
  prop_mat = freq_mat ./ sum2;  
  prop_mat(sum2 == 0, :) = 0;
  
  freq_mats{i} = freq_mat;
  prop_mats{i} = prop_mat;
end

freq_mat = sum_many( freq_mats{:} );
freq_mat = freq_mat ./ sum( freq_mat, 2 );

prop_mat = sum_many( prop_mats{:} );
prop_mat = prop_mat ./ numel( prop_mats );

%%

assert_ispair( freq_mats, freq_labs );
sesh_I = findall( freq_labs, 'session' );
sesh_mats = cellfun( @(x) sum_many(freq_mats{x}), sesh_I, 'un', 0 );

sesh_prop_mats = cell( size(sesh_mats) );
for i = 1:numel(sesh_mats)
  sum2 = sum( sesh_mats{i}, 2 );
  prop_mat = sesh_mats{i} ./ sum2;  
  prop_mat(sum2 == 0, :) = 0;
  sesh_prop_mats{i} = prop_mat;
end

sesh_prop_mat = sum_many( sesh_prop_mats{:} );
sesh_prop_mat = sesh_prop_mat ./ numel( sesh_prop_mats );
sesh_freq_mat = mean_many( sesh_mats{:} );

%%  proportion matrix heatmap

ax = gca;
cla( ax );
imagesc( sesh_prop_mat );
set( ax, 'xtick', 1:numel(rois) );
set( ax, 'xticklabel', strrep(rois, '_', ' ') );
set( ax, 'ytick', 1:numel(rois) );
set( ax, 'yticklabel', strrep(rois, '_', ' ') );
colormap( 'jet' );
axis( ax, 'square' );
% shared_utils.plot.set_clims( ax, [0, 0.18] );
colorbar;

for i = 1:numel(rois)
  for j = 1:numel(rois)
    x = j;
    y = i;
    text( x, y, sprintf('N = %0.2f', sesh_freq_mat(i, j)), 'color', 'white' );
  end
end

%%  frequency counts

assert_ispair( freq_mats, freq_labs );
addcat( freq_labs, 'next-roi' );

count_labs = fcat();
freq_counts = [];
for i = 1:numel(freq_mats)
  for j = 1:numel(rois)
    for k = 1:numel(rois)
      append( count_labs, freq_labs, i );
      setcat( count_labs, 'next-roi', sprintf('next-%s', rois{k}), rows(count_labs) );
      setcat( count_labs, 'roi', rois{j}, rows(count_labs) );
      freq_counts(end+1, 1) = freq_mats{i}(j, k);
      assert_ispair( freq_counts, count_labs );
    end
  end
end

%%  sum frequencies across runs, within session

assert_ispair( freq_counts, count_labs );
[sesh_labs, sesh_I] = keepeach( count_labs', {'roi', 'next-roi', 'session'} );
sesh_sums = cellfun( @(x) sum(freq_counts(x)), sesh_I );
pl = plotlabeled.make_common();
axs = pl.bar( sesh_sums, sesh_labs, 'roi', 'next-roi', {} );

%%  load spikes

spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes', 'include_unit_index', true );
bfw.apply_new_cell_id_labels( spikes.labels, bfw_load_cell_id_matrix );

%%  psth

evt_mask = pipe( rowmask(behav_events.labels) ...
  , @(m) find(behav_events.labels, {'eyes_nf', 'face', 'nonsocial_object'}, m) ...
  , @(m) find(behav_events.labels, 'free_viewing', m) ...
);

[evt_I, evt_C] = findall( behav_events.labels, {'unified_filename', 'session'}, evt_mask );
spk_I = bfw.find_combinations( spikes.labels, evt_C(2, :) );

start_ts = bfw.event_column( behav_events, 'start_time' );
[psth, psth_t] = bfw.event_psth( start_ts, spikes.spike_times, evt_I, spk_I, -1, 1, 0.05 );
psth_labels = bfw.event_psth_labels( behav_events.labels, spikes.labels, evt_I, spk_I );

psth = vertcat( psth{:} );
psth_labels = vertcat( fcat, psth_labels{:} );
assert_ispair( psth, psth_labels );
assert( numel(psth_t) == size(psth, 2) );

%%  n-1 psth

n1_psth_labels = psth_labels';

evt_I = findall( psth_labels, {'unified_filename', 'unit_uuid'} );
prev_roi_cat = 'prev-roi';
addcat( n1_psth_labels, prev_roi_cat );

for i = 1:numel(evt_I)
  curr_ind = evt_I{i}(2:end);
  curr_rois = cellstr( n1_psth_labels, 'roi', curr_ind );
  prev_rois = cellstr( n1_psth_labels, 'roi', evt_I{i}(1:end-1) );
  prev_rois = cellfun( @(x) sprintf('prev-%s', x), prev_rois, 'un', 0 );
  setcat( n1_psth_labels, prev_roi_cat, prev_rois, curr_ind );
end

%%  compare pairs of n-1 rois

curr_rois = combs( psth_labels, 'roi' );
roi_pairs = bfw.pair_combination_indices( numel(curr_rois) );
collapsed_psth = nanmean( psth(:, psth_t >= 0 & psth_t < 0.05), 2 );

rs_labels = fcat();
rs_tbls = {};

for i = 1:numel(curr_rois)
  shared_utils.general.progress( i, numel(curr_rois) );
  
  curr_ind = find( n1_psth_labels, curr_rois{i} );
  for j = 1:size(roi_pairs, 1)
    a = curr_rois{roi_pairs(j, 1)};
    b = curr_rois{roi_pairs(j, 2)};
    ap = sprintf( 'prev-%s', a );
    bp = sprintf( 'prev-%s', b );
    rs_outs = dsp3.ranksum( collapsed_psth, n1_psth_labels, {'unit_uuid'}, ap, bp ...
      , 'mask', curr_ind ...
    );
    setcat( rs_outs.rs_labels, prev_roi_cat, sprintf('%s v %s', ap, bp) );
    append( rs_labels, rs_outs.rs_labels );
    rs_tbls = [ rs_tbls; rs_outs.rs_tables ];
  end
end

assert_ispair( rs_tbls, rs_labels );

%%  proportion significant

rs_ps = cellfun( @(x) x.p, rs_tbls );
rs_sig = rs_ps < 0.05;
[prop_labels, prop_I] = keepeach( rs_labels', {'region', 'roi', prev_roi_cat} );
props = cellfun( @(x) sum(rs_sig(x)) / numel(x), prop_I );

pl = plotlabeled.make_common();
axs = pl.bar( props, prop_labels, {prev_roi_cat}, {'region'}, 'roi' );
ylabel( axs(1), 'Prop. significant' )

