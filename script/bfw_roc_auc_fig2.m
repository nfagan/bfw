%%  Load data

all_files = shared_utils.io.findmat( bfw.gid('raw_events_remade') );
all_files = shared_utils.io.filenames( all_files, true );
sessions = cellfun( @(x) x(1:8), all_files, 'un', 0 );
unique_sessions = unique( sessions );
num_session_bins = 5;
binned_sessions = shared_utils.vector.distribute( 1:numel(unique_sessions), num_session_bins );
binned_sessions = cellfun( @(x) unique_sessions(x), binned_sessions, 'un', 0 );

session_auc = {};

bin_size = 1e-2;
step_size = 1e-2; % 10ms
look_back = -0.5;
look_ahead = 0.5;

%%

for session_index = 1:numel(binned_sessions)
  
shared_utils.general.progress( session_index, numel(binned_sessions) );

seshs = binned_sessions{session_index};
sesh_ind = ismember( sessions, seshs );

select_files = all_files(sesh_ind);

% select_files = [
%   {'01042019'}
%   {'01092019'}
%   {'01112019'}
%   {'01132019'}
%   {'01152019'}
%   {'02042018'}
%   {'09292018'}
%   {'10092018'}
% ];

res = bfw_make_psth_for_fig1( ...
    'is_parallel', true ...
  , 'window_size', bin_size ...
  , 'step_size', step_size ...
  , 'look_back', look_back ...
  , 'look_ahead', look_ahead ...
  , 'files_containing', select_files(:)' ...
  , 'include_rasters', false ...
  , 'collapse_nonsocial_object_rois', true ...
);

%%  Add whole face roi

gaze_counts = res.gaze_counts;
gaze_counts = add_whole_face_roi( gaze_counts );
gaze_counts = add_whole_object_roi( gaze_counts );

%%  Remove nonsocial object events prior to the actual introduction of the object.

base_mask = get_base_mask( gaze_counts.labels );

%%  Auc for each unit, test significance with permutation test

labels = gaze_counts.labels';
spikes = gaze_counts.spikes;

smooth_each = true;
if ( smooth_each )
  for i = 1:size(spikes, 1)
    spikes(i, :) = movsum( spikes(i, :), 10 );
  end
end

perm_iters = 1e2;
n_consecutive = 5;

units_each = { 'unit_uuid', 'unit_index', 'region', 'session' };
roi_pairs = { ...
    {'whole_face', 'nonsocial_object_whole_face_matched'} ...
  , {'eyes_nf', 'nonsocial_object_eyes_nf_matched'} ...
  , {'eyes_nf', 'face'} ...
};

mask = fcat.mask( labels, base_mask );
[unit_labels, unit_I] = keepeach( labels', units_each, mask );

auc_labels = cell( numel(unit_I), 1 );
auc = cell( size(auc_labels) );
auc_sig_info = cell( size(auc_labels) );

parfor i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  tmp_auc = [];
  tmp_sig_info = {};
  tmp_auc_labels = fcat();
  
  for j = 1:numel(roi_pairs)
    roi_a = roi_pairs{j}{1};
    roi_b = roi_pairs{j}{2};
    ind_a = find( labels, roi_a, unit_I{i} );
    ind_b = find( labels, roi_b, unit_I{i} );
    
    [real_auc, sig_info] = auc_for_pair( spikes, ind_a, ind_b, perm_iters, n_consecutive );
    labs = setcat( unit_labels(i), 'roi', sprintf('%s_%s', roi_a, roi_b) );
    
    append( tmp_auc_labels, labs );
    tmp_auc = [ tmp_auc; real_auc ];
    tmp_sig_info{end+1, 1} = sig_info;
  end
  
  auc_labels{i} = tmp_auc_labels;
  auc{i} = tmp_auc;
  auc_sig_info{i} = vertcat( tmp_sig_info{:} );
end

auc = vertcat( auc{:} );
auc_labels = vertcat( fcat, auc_labels{:} );
auc_sig_info = vertcat( auc_sig_info{:} );

session_auc{session_index} = struct( 'auc', auc, 'auc_labels', auc_labels, 'auc_sig_info', auc_sig_info );

end

%%  or load

auc_info = load( fullfile(bfw.dataroot, 'analyses/auc/042121/session_auc.mat') );
session_auc = auc_info.session_auc;
gaze_counts = struct();
gaze_counts.t = look_back:step_size:look_ahead;

%%  concatenate

auc_info = vertcat( session_auc{:} );
auc = cat_expanded( 1, {auc_info.auc} );
auc_labels = cat_expanded( 1, {fcat, auc_info.auc_labels} );
auc_sig_info = cat_expanded( 1, {auc_info.auc_sig_info} );

%%  extract subset

save_subset = false;
select_roi = 'eyes_nf_nonsocial_object_eyes_nf_matched';

roi_ind = find( auc_labels, select_roi );
subset_auc = auc(roi_ind, :);
subset_auc_labels = gather( auc_labels(roi_ind) );

subset_info = struct();
subset_info.t = t;
subset_info.auc = subset_auc;
subset_info.labels = subset_auc_labels';

if ( save_subset )
  save_p = fullfile( bfw.dataroot, 'analyses/auc', dsp3.datedir );
  shared_utils.io.require_dir( save_p );
  save( fullfile(save_p, 'subset_auc.mat'), 'subset_info' );
end

%%  Plot heat maps

plt_auc = auc;
plt_auc_labels = auc_labels';
plt_auc_sig_info = auc_sig_info;
t = gaze_counts.t;

assert_ispair( plt_auc, plt_auc_labels );
assert_ispair( plt_auc_sig_info, plt_auc_labels );

is_sig = [ plt_auc_sig_info.sig_neg ] | [ plt_auc_sig_info.sig_pos ];

figs_each = { 'roi' };

plt_mask = get_base_mask( plt_auc_labels, false );
[fig_auc_labels, fig_I] = keepeach( plt_auc_labels', figs_each, plt_mask );
f = figure(1);

c_lims = [0.3, 0.7];

conf = bfw.config.load();
do_save = true;

gt_lt_counts = [];
gt_lt_labels = fcat();

pre_post_counts = [];
pre_post_count_labels = fcat();

tot_sig_counts = [];
tot_sig_labels = fcat();

prop_p_stats = [];
prop_p_labels = fcat();

pre_post_prop_p_stats = [];
pre_post_prop_p_labels = fcat();

pair_sig_stats = cell( numel(fig_I), 1 );
pair_sig_labs = cell( size(pair_sig_stats) );

for i = 1:numel(fig_I)
  clf();
  
  [p_I, p_C] = findall( plt_auc_labels, [{'region'}, figs_each], fig_I{i} );
  ss = plotlabeled.get_subplot_shape( numel(p_I) );
  
  num_sig_info = zeros( numel(p_I), 2 );
  gt_first_ts = cell( numel(p_I), 1 );
  lt_first_ts = cell( numel(p_I), 1 );
  
  for j = 1:numel(p_I)
    ax = subplot( ss(1), ss(2), j );
    cla( ax );
    hold( ax, 'on' );
    
    p_ind = p_I{j};
    sig_p_ind = p_ind(is_sig(p_ind));
    [sort_ind, first_sig] = sort_sig( plt_auc_sig_info(sig_p_ind) );
    sig_p_ind = sig_p_ind(sort_ind);    
    sub_auc = plt_auc(sig_p_ind, :);
    
    tmp_labels = one( plt_auc_labels(p_ind) );
    
    first_sig_t = t(first_sig);
    n_pre = sum( first_sig_t < 0 );
    n_post = sum( first_sig_t >= 0 );
    n_tot = n_pre + n_post;
    
    [~, pre_post_prop_p, pre_post_prop_chi2] = prop_test( [n_pre, n_post], [n_tot, n_tot], false );
    tmp_pre_post_labs = addcat( tmp_labels', 'epoch' );
    repset( tmp_pre_post_labs, 'epoch', {'pre', 'post'} );
    
    pre_post_prop_p_stats = [ pre_post_prop_p_stats; [pre_post_prop_p, pre_post_prop_chi2] ];
    append( pre_post_prop_p_labels, tmp_labels );
    
    pre_post_counts = [ pre_post_counts; n_pre; n_post ];
    append( pre_post_count_labels, tmp_pre_post_labs );
    
    first_sig_auc_val = arrayfun( @(x) sub_auc(x, first_sig(x)), 1:numel(first_sig) );
    n_greater = sum( first_sig_auc_val >= 0.5 );
    n_less = sum( first_sig_auc_val < 0.5 );
    n_tot = n_greater + n_less;    
    
    [~, prop_p, prop_chi2] = prop_test( [n_greater, n_less], [n_tot, n_tot], false );
    
    tmp_gt_lt_labels = addcat( tmp_labels', 'direction' );
    repset( tmp_gt_lt_labels, 'direction', {'less', 'greater'} );
    
    gt_lt_counts = [ gt_lt_counts; n_less; n_greater ];
    append( gt_lt_labels, tmp_gt_lt_labels );
    
    prop_p_stats = [ prop_p_stats; [prop_p, prop_chi2] ];
    append( prop_p_labels, tmp_labels );
    
    h_im = imagesc( ax, t, 1:size(sub_auc, 1), sub_auc );
    
    first_xs = gaze_counts.t(first_sig);
    first_ys = 1:numel(first_sig);
    plot_white_lines( ax, first_xs, first_ys );
    
    num_sig = numel( sig_p_ind );
    num_tot = numel( p_ind );
    
    tot_sig_counts = [ tot_sig_counts; [num_sig, num_tot] ];
    num_sig_info(j, :) = [ num_sig, num_tot ];
    append( tot_sig_labels, tmp_labels );
    
    pc_str = strrep( strjoin(p_C(:, j), ' | '), '_', ' ' );
    title_str = sprintf( '%s (%d of %d [%0.2f%%])', pc_str ...
      , num_sig, num_tot, num_sig/num_tot*100 );
    title( ax, title_str );
    
    shared_utils.plot.set_clims( ax, c_lims );
    shared_utils.plot.set_xlims( ax, [min(t), max(t)] );
    shared_utils.plot.set_ylims( ax, [1, numel(sig_p_ind)] );
    
    colormap( 'jet' );
    colorbar;
    
    gt_first_ts{j} = first_sig_t(first_sig_auc_val >= 0.5);
    lt_first_ts{j} = first_sig_t(first_sig_auc_val < 0.5);
  end
  
  pair_i = pair_combination_indices( numel(p_I) );
  reg_pairs = arrayfun( ...
    @(x, y) sprintf('%s_%s', p_C{1, x}, p_C{1, y}), pair_i(:, 1), pair_i(:, 2), 'un', 0 );
  
  pair_stats = pair_prop_tests( num_sig_info, pair_i );
  pair_stats(:, 1) = dsp3.fdr( pair_stats(:, 1) );
  
  pair_sig_stats{i} = pair_stats;
  pair_sig_labs{i} = setcat( repmat(fig_auc_labels(i), size(pair_i, 1)), 'region', reg_pairs );
  
  if ( do_save )
    save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'heatmaps' );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, prune(plt_auc_labels(fig_I{i})), [{'region'}, figs_each] );
  end
  
  all_hist_axs = gobjects( 0 ); 
  for j = 1:numel(gt_first_ts)
    ax_lt = subplot( ss(1) * 2, ss(2), (j-1)*2 + 1 );
    ax_gt = subplot( ss(1) * 2, ss(2), (j-1)*2 + 2 );
    
    cla( ax_lt );
    cla( ax_gt );
    hold( ax_lt, 'on' );
    hold( ax_gt, 'on' );
    
    h_gt = histogram( ax_gt, gt_first_ts{j}, 100 );
    h_lt = histogram( ax_lt, lt_first_ts{j}, 100 );
    
    med_gt = nanmedian( gt_first_ts{j} );
    med_lt = nanmedian( lt_first_ts{j} );
    
    is_sig_gt = signrank( gt_first_ts{j} ) < 0.05;
    is_sig_lt = signrank( lt_first_ts{j} ) < 0.05;
    
    sig_hist = ranksum( gt_first_ts{j}, lt_first_ts{j} ) < 0.05;
    if ( sig_hist )
      sig_str = ' (*)';
    else
      sig_str = '';
    end
    
    shared_utils.plot.add_vertical_lines( ax_gt, med_gt );
    shared_utils.plot.add_vertical_lines( ax_lt, med_lt );
    text( ax_gt, med_gt, max(get(ax_gt, 'ylim')), sprintf('M=%0.2f%s', med_gt, sig_str) );
    text( ax_lt, med_lt, max(get(ax_lt, 'ylim')), sprintf('M=%0.2f%s', med_lt, sig_str) );
    
    set( h_gt, 'FaceColor', [1, 0, 0] );
    set( h_gt, 'FaceAlpha', 1 );
    set( h_lt, 'FaceColor', [0, 0, 1] );
    set( h_lt, 'FaceAlpha', 1 );
    
    all_hist_axs(end+1, 1) = ax_lt;
    all_hist_axs(end+1, 1) = ax_gt;
    
    title_str = strrep( strjoin(p_C(:, j), ' | '), '_', ' ' );
    title_str_gt = title_str;
    title_str_lt = title_str;
    
    if ( is_sig_gt )
      title_str_gt = sprintf( '%s (*)', title_str );
    end
    if ( is_sig_lt )
      title_str_lt = sprintf( '%s (*)', title_str );
    end
    
    title( ax_gt, title_str_gt );
    title( ax_lt, title_str_lt );
  end
  
  shared_utils.plot.set_xlims( all_hist_axs, [min(t), max(t)] );
  shared_utils.plot.match_ylims( all_hist_axs );
  
  if ( do_save )
    save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'hist' );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, prune(plt_auc_labels(fig_I{i})), [{'region'}, figs_each] );
  end
end

pair_sig_stats = vertcat( pair_sig_stats{:} );
pair_sig_labs = vertcat( fcat, pair_sig_labs{:} );
assert_ispair( pair_sig_stats, pair_sig_labs );

%%  prop test

do_save = true;

% stats_type = 'gt_lt';
stats_type = 'pre_post';
% stats_type = 'total';

assert_ispair( gt_lt_counts, gt_lt_labels );
assert_ispair( prop_p_stats, prop_p_labels );
assert_ispair( pre_post_counts, pre_post_count_labels );
assert_ispair( pre_post_prop_p_stats, pre_post_prop_p_labels );
assert_ispair( tot_sig_counts, tot_sig_labels );

row_cats = { 'region', 'roi' };
stat_prefix = sprintf( 'stats_%s', stats_type );

switch ( stats_type )
  case 'gt_lt'    
    [chi2_stats, chi2_labels] = dsp3.chi2_tabular_frequencies( ...
      gt_lt_counts, gt_lt_labels, 'roi', 'direction', 'region' );
    
    prop_table_row_labels = prop_p_labels(:, row_cats);
    t = array2table(prop_p_stats, 'variablenames', {'p', 'chi2'});
    t.Properties.RowNames = fcat.strjoin( prop_table_row_labels', ' | ' );
  
  case 'pre_post'
    [chi2_stats, chi2_labels] = dsp3.chi2_tabular_frequencies( ...
      pre_post_counts, pre_post_count_labels, 'roi', 'epoch', 'region' );
    
    prop_table_row_labels = pre_post_prop_p_labels(:, row_cats);
    t = array2table(pre_post_prop_p_stats, 'variablenames', {'p', 'chi2'});
    t.Properties.RowNames = fcat.strjoin( prop_table_row_labels', ' | ' );
    
  case 'total'
    [chi2_stats, chi2_labels] = dsp3.chi2_tabular_frequencies( ...
      tot_sig_counts(:, 1), tot_sig_labels, {}, 'roi', 'region' );
    
    prop_table_row_labels = pair_sig_labs(:, row_cats);
    t = array2table(pair_sig_stats, 'variablenames', {'p', 'chi2'});
    t.Properties.RowNames = fcat.strjoin( prop_table_row_labels', ' | ' );
    
  otherwise
    error( 'Unhandled stats type "%s".', stats_type );
end

t2 = [ [chi2_stats.p]', [chi2_stats.chi2]' ];
t2 = array2table( t2, 'variablenames', {'p', 'chi2'} ...
  , 'RowNames', fcat.strjoin(chi2_labels(:, row_cats)', ' | ') );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, stat_prefix );
  dsp3.req_writetable( t, save_p, prop_p_labels, row_cats, 'within_region__' );
  dsp3.req_writetable( t2, save_p, chi2_labels, row_cats, 'across_regions__' );
end

%%  Plot average AUC traces

plt_auc = auc;
plt_auc(plt_auc < 0.5) = (0.5 - plt_auc(plt_auc < 0.5)) + 0.5;

plt_auc_labels = auc_labels';
plt_auc_sig_info = auc_sig_info;
t = gaze_counts.t;
is_sig = [ plt_auc_sig_info.sig_neg ] | [ plt_auc_sig_info.sig_pos ];

plt_mask = get_base_mask( plt_auc_labels, false );
plt_mask = intersect( plt_mask, find(is_sig) );

plt_auc = plt_auc(plt_mask, :);
plt_auc_labels = plt_auc_labels(plt_mask);

pl = plotlabeled.make_common();
pl.x = t;
axs = pl.lines( plt_auc, plt_auc_labels, 'region', 'roi' );

do_save = true;
conf = bfw.config.load();

pre_auc = nanmean( plt_auc(:, t < 0), 2 );
post_auc = nanmean( plt_auc(:, t >= 0), 2 );
combined_auc = [ pre_auc; post_auc ];
combined_auc_labels = repset( addcat(plt_auc_labels', 'epoch'), 'epoch', {'pre', 'post'} );
rs_outs = dsp3.ranksum( combined_auc, combined_auc_labels, {'region', 'roi'}, 'pre', 'post' );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'avg_traces' );
  stat_p = fullfile( save_p, 'stats' );
  
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, plt_auc_labels, 'region' );
  dsp3.save_ranksum_outputs( rs_outs, stat_p );
end

%%  Plot bar AUC summary

do_save = true;
y_lims = [ 0, 1 ];

plt_auc = auc;
plt_auc_labels = auc_labels';
t = gaze_counts.t;
[is_sig, is_neg] = arrayfun( @(x) sorting_index_value(x), auc_sig_info );

plt_mask = get_base_mask( plt_auc_labels, false );
plt_mask = intersect( plt_mask, find(is_sig) );

fig_I = findall( plt_auc_labels, {'roi', 'region'}, plt_mask );
for i = 1:numel(fig_I)
  sub_neg = is_neg(fig_I{i});
  sub_pos = ~sub_neg;
  assert( all(is_sig(fig_I{i})) );
  
  pos_i = fig_I{i}(sub_pos);
  neg_i = fig_I{i}(sub_neg);
  
  pos_inds = [auc_sig_info(pos_i).first_pos];
  neg_inds = [auc_sig_info(neg_i).first_neg];
  assert( numel(pos_inds) + numel(neg_inds) == numel(fig_I{i}) );
  
  pos_t = t(pos_inds);
  neg_t = t(neg_inds);
  
  p_pos_pre = pnz( pos_t < 0 );
  p_pos_post = 1 - p_pos_pre;
  p_neg_pre = pnz( neg_t < 0 );
  p_neg_post = 1 - p_neg_pre;
  
  pos_pre_i = pos_i(pos_t < 0);
  pos_post_i = pos_i(pos_t >= 0);
  neg_pre_i = neg_i(neg_t < 0);
  neg_post_i = neg_i(neg_t >= 0);  
  
  pos_pre_auc = nanmean( plt_auc(pos_pre_i, t < 0), 2 );
  pos_post_auc = nanmean( plt_auc(pos_post_i, t >= 0), 2 );
  neg_pre_auc = nanmean( plt_auc(neg_pre_i, t < 0), 2 );
  neg_post_auc = nanmean( plt_auc(neg_post_i, t >= 0), 2 );
  
  auc_value_labels = {'AUC > 0.5', 'AUC > 0.5', 'AUC < 0.5', 'AUC < 0.5'};
  auc_epoch_labels = {'pre', 'post', 'pre', 'post'};
  auc_values = { pos_pre_auc, pos_post_auc, neg_pre_auc, neg_post_auc };
  
  f = one( plt_auc_labels(fig_I{i}) );
  repmat( f, 4 );
  addsetcat( f, 'epoch', auc_epoch_labels );
  addsetcat( f, 'auc_value', auc_value_labels );
  
  p_cats = { 'roi', 'region', 'auc_value' };
  
  ps = [ p_pos_pre; p_pos_post; p_neg_pre; p_neg_post ];  
  pl = plotlabeled.make_common();
  pl.x_order = { 'pre', 'post' };
  pl.y_lims = y_lims;  
  axs = pl.bar( ps, f, 'epoch', {}, p_cats );
  if ( do_save )
    save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'prop_sig_bin_pre_post' );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, f, p_cats );
  end
  
  f2 = fcat();  
  auc_vals = [];
  
  for j = 1:numel(auc_value_labels)
    f_tmp = f(j);
    repmat( f_tmp, numel(auc_values{j}) );
    append( f2, f_tmp );
    auc_vals = [ auc_vals; auc_values{j} ];
  end
  
  pl = plotlabeled.make_common();
  pl.add_points = true;
  pl.x_order = { 'pre', 'post' };
  pl.y_lims = y_lims;
  pl.marker_size = 2;
  pl.points_are = { 'session' };
  axs = pl.bar( auc_vals, f2, 'epoch', {}, p_cats );
  if ( do_save )
    save_p = fullfile( bfw.dataroot(conf), 'plots/auc', dsp3.datedir, 'avg_auc_bar' );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, f2, p_cats );
  end
end

%%

function plot_white_lines(ax, xs, ys)

for i = 1:numel(xs)-1
  x0 = xs(i);
  x1 = xs(i+1);
  y0 = ys(i);
  y1 = ys(i+1);
  h = plot( ax, [x0; x1], [y0; y1] );
  set( h, 'color', ones(1, 3) );
  set( h, 'linewidth', 4 );
end

end

function [real_auc, sig_info] = auc_for_pair(spikes, ind_a, ind_b, perm_iters, n_consecutive)

assert( perm_iters == 100 );  % expect p < 0.01

if ( isempty(ind_a) || isempty(ind_b) )
  real_auc = nan( 1, size(spikes, 2) );
  null_aucs = nan( perm_iters, size(spikes, 2) );
  
else
  real_auc = auc_over_time( spikes, ind_a, ind_b );

  null_aucs = cell( perm_iters, 1 );
  for k = 1:perm_iters
    [ia, ib] = shuffle2( ind_a, ind_b );
    null_aucs{k} = auc_over_time( spikes, ia, ib );
  end
  null_aucs = vertcat( null_aucs{:} );
  null_aucs = sort( null_aucs );
end

sig_le = real_auc < null_aucs(1, :);
sig_gt = real_auc > null_aucs(end, :);
[isles_le, durs_le] = find_consecutive( sig_le, n_consecutive );
[isles_gt, durs_gt] = find_consecutive( sig_gt, n_consecutive );

sig_info = struct();
sig_info.sig_neg = ~isempty( isles_le );
sig_info.sig_pos = ~isempty( isles_gt );
sig_info.first_neg = min( isles_le );
sig_info.first_pos = min( isles_gt );

end

function aucs = auc_over_time(spikes, ind_a, ind_b)

aucs = nan( 1, size(spikes, 2) );

for i = 1:size(spikes, 2)
  spks_a = spikes(ind_a, i);
  spks_b = spikes(ind_b, i);
  auc = score_auc( spks_a, spks_b );
  aucs(i) = auc;
end

end

function auc = score_auc(a, b)

t = false( numel(a) + numel(b), 1 );
t(1:numel(a)) = true;
y = [ a; b ];
auc = scoreAUC( t, y );

end

function [auc, tpr, fpr] = roc_auc(a, b)

t = false( numel(a) + numel(b), 1 );
t(1:numel(a)) = true;

y = [ a; b ];
[tpr, fpr] = roc( t(:)', y(:)' );

if ( abs(max(fpr)-1) >= eps )
  fpr(end+1) = 1;
  tpr(end+1) = 1;
end

auc = trapz( fpr, tpr );

end

function [i, d] = find_consecutive(v, ct)

[i, d] = shared_utils.logical.find_islands( v );
thresh = d >= ct;
i = i(thresh);
d = d(thresh);

end

function [ic, id] = shuffle2(ia, ib)

i = [ia; ib];
i = i(randperm(numel(i)));
ic = i(1:numel(ia));
id = i(numel(ia)+1:end);
assert( numel(ic) == numel(ia) && numel(id) == numel(ib) );

end

function base_mask = get_base_mask(labels, only_remove_obj)

if ( nargin < 2 )
  only_remove_obj = true;
end

if ( only_remove_obj )
  sesh_mask = findor( labels, ns_obj_roi_labels() );
else
  sesh_mask = rowmask( labels );
end

base_mask = bfw.find_sessions_before_nonsocial_object_was_added( labels, sesh_mask );
base_mask = setdiff( rowmask(labels), base_mask );

end

function rois = ns_obj_roi_labels()
rois = { 'nonsocial_object', 'nonsocial_object_eyes_nf_matched', 'nonsocial_object_whole_face_matched' };
end

function gaze_counts = add_whole_face_roi(gaze_counts)

gaze_counts.labels = gaze_counts.labels';
[~, transform_ind] = bfw.make_whole_face_roi( gaze_counts.labels );
gaze_counts = index_gaze_counts( gaze_counts, transform_ind );

end

function gaze_counts = add_whole_object_roi(gaze_counts)

gaze_counts.labels = gaze_counts.labels';
[~, transform_ind] = bfw.make_whole_object_roi( gaze_counts.labels );
gaze_counts = index_gaze_counts( gaze_counts, transform_ind );

end

function gaze_counts = index_gaze_counts(gaze_counts, transform_ind)

gaze_counts.spikes = gaze_counts.spikes(transform_ind, :);
gaze_counts.events = gaze_counts.events(transform_ind, :);

end

function [ind, vs] = sort_sig(sig_info)

vs = zeros( numel(sig_info), 1 );
is_neg = false( size(vs) );

for i = 1:numel(sig_info)
  [~, is_neg(i), vs(i)] = sorting_index_value( sig_info(i) );
end

src_ind = 1:numel(sig_info);

src_neg = src_ind(is_neg);
[neg_vs, neg_ind] = sort( vs(is_neg), 'desc' );
neg_ind = src_neg(neg_ind);

src_pos = src_ind(~is_neg);
[pos_vs, pos_ind] = sort( vs(~is_neg) );
pos_ind = src_pos(pos_ind);

ind = [ neg_ind(:); pos_ind(:) ];
vs = [ neg_vs(:); pos_vs(:) ];

end

function [is_sig, is_neg, s] = sorting_index_value(sig_info)

is_sig = false;
is_neg = false;
s = 0;

if ( sig_info.sig_pos && ~sig_info.sig_neg )
  is_sig = true;
  s = sig_info.first_pos;
end
if ( ~sig_info.sig_pos && sig_info.sig_neg )
  is_sig = true;
  s = sig_info.first_neg;
  is_neg = true;
end
if ( sig_info.sig_pos && sig_info.sig_neg )
  is_sig = true;
  if ( sig_info.first_pos < sig_info.first_neg )
    s = sig_info.first_pos;
  else
    s = sig_info.first_neg;
    is_neg = true;
  end
end

end

function stats = pair_prop_tests(counts, inds)

stats = zeros( size(inds, 1), 2 );

for i = 1:size(inds, 1)
  ind = inds(i, :);
  num_a = counts(ind(1), 1);
  num_b = counts(ind(2), 1);
  tot_a = counts(ind(1), 2);
  tot_b = counts(ind(2), 2);
  
  [~, p, chi2] = prop_test( [num_a, num_b], [tot_a, tot_b], false );
  stats(i, :) = [ p, chi2 ];
end

end

function i = pair_combination_indices(n)

i = unique( sort(dsp3.ncombvec(n, n), 1)', 'rows' );
i(i(:, 1) == i(:, 2), :) = [];

end