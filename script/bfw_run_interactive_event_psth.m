%%  load

look_vec = shared_utils.io.fload( fullfile(bfw.dataroot, 'public/look_vector_20.mat') );

is_par = true;

events = bfw_gather_events( 'require_stim_meta', false, 'is_parallel', is_par );
spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes', 'is_parallel', is_par );
time = bfw_gather_aligned_samples( 'input_subdirs', 'time', 'is_parallel', is_par );

src_spike_labels = spikes.labels';

%%  cc spike labels

cc_spike_labels = make_cc_spike_labels( src_spike_labels' );

%%  

use_cc_labels = true;
use_randomized_labels = false;

if ( use_randomized_labels )
  spikes.labels = randomize_unit_uuids( src_spike_labels' );
  
elseif ( use_cc_labels )
  spikes.labels = cc_spike_labels';
  
else
  spikes.labels = src_spike_labels';
end

%%  define interactive events

event_mask_func = @(l, m) pipe(m ...
  , @(m) find(l, 'eyes_nf', m) ...
  , @(m) find(l, 'free_viewing', m) ...
  , @(m) findnone(l, {'simultaneous_initiated', 'simultaneous_terminated'}, m) ...
);

new_event_res = bfw_define_interactive_events( events, look_vec ...
  , 'mask_func', event_mask_func ...
  , 'use_gaze_control_for_solo', true ...
  , 'include_mutual', false ...
);

%%  or use chengchis

cc_event_res = load_cc_event_res( bfw.config.load(), time );

%%

event_res = cc_event_res;

%%

original_cell_ids = [ 710, 41, 485, 790, 158, 700, 948, 187, 1038, 142, 1175, 165, 1038, 142, 1175, 165 ];
% original_cell_ids = [ 761, 1095, 1092, 253, 1516, 819, 1123, 379, 1507, 791, 1119, 393, 1738 ];
% original_cell_ids = [ 761, 819, 791, 1095, 1123, 1119, 253, 379, 393, 1516, 1507, 1738 ];

original_unit_ids = arrayfun( @(x) sprintf('unit_uuid__%d', x), original_cell_ids, 'un', 0 );

psth_mats = struct();

%%  make psth

psth_min_t = -1;
psth_max_t = 1;
psth_bin_size = 0.01;

subset_spikes = keep_spikes( spikes, find(spikes.labels, original_unit_ids) );
% subset_spikes = spikes;

[psth, psth_labels, psth_t, event_inds, time_inds] = ...
  make_psth( event_res, subset_spikes, time, psth_min_t, psth_max_t, psth_bin_size );

psth = psth * (1 / psth_bin_size);

if ( psth_bin_size == 0.01 )
  psth_mats.ten_ms = psth;
  psth_mats.ten_ms_t = psth_t;
elseif ( psth_bin_size == 0.05 )
  psth_mats.fifty_ms = psth;
  psth_mats.fifty_ms_t = psth_t;
else
  warning( 'Possibly unhandled bin size "%0.2f"', psth_bin_size );
end

%%  plot psths

unit_mask = fcat.mask( psth_labels ...
  , @find, {'solo-type', 'joint-type'} ...
);

perm_test_func = @(x, y) psth_permutation_test(x, y, 1e3, 0.95);
rs_test_func = @(x, y) ranksum(x, y) < 0.05;
sig_test_func = rs_test_func;

plot_psth( psth_mats.ten_ms, psth_labels, psth_mats.ten_ms_t ...
  , event_res, time, event_inds, time_inds, unit_mask ...
  , 'do_save', true ...
  , 'add_smoothing', true ...
  , 'add_error_lines', false ...
  , 'sig_test_func', sig_test_func ...
  , 'stats_psth', psth_mats.ten_ms ...
  , 'stats_psth_t', psth_mats.ten_ms_t ...
  , 'unit_cats', {'unit_uuid', 'region', 'session'} ...
);

%%

anova_cells = bfw_ct.load_significant_social_cell_labels_from_anova();

%%  count significant

unit_mask = fcat.mask( psth_labels ...
  , @find, {'solo-type', 'joint-type'} ...
);

% use_denom = anova_cells;
use_denom = [];
[counts, unit_counts, count_labels] = count_significant_types( psth, psth_labels', psth_t, unit_mask ...
  , 'denominator_unit_labels', use_denom ...
);

%%  chi2

per_event_type = true;
chi_labels = count_labels';
use_counts = counts;

if ( ~per_event_type )
  [chi_labels, each_I] = keepeach( chi_labels', setdiff(getcats(chi_labels), 'psth_sig_counts') );
  num_sig = cellfun( @(x) sum(counts(x)), each_I );
  num_nsig = cellfun( @(x) sum(unique(unit_counts(x)) - counts(x)), each_I );
  chi_labels = repset( chi_labels, 'psth_sig_counts', {'sig', 'not-sig'} );
  use_counts = [ num_sig; num_nsig ];
end

[chi_labels, chi_I] = keepeach( chi_labels', {'psth_epoch'} );
ps = zeros( size(chi_I) );

for i = 1:numel(chi_I)
  [t, rowc, colc] = tabular( count_labels, 'psth_sig_counts', 'region', chi_I{i} );
  t = cellfun( @(x) use_counts(x), t );
  sr = sum( t, 1 );
  sc = sum( t, 2 );
  expect = sr .* (sc ./ sum(sc));
  chi2 = t - expect;
  chi2 = (chi2 .* chi2) ./ expect;
  chi2 = sum( sum(chi2) );
  df = (size(t, 1) - 1) * (size(t, 2) - 1);
  ps(i) = gammainc( chi2/2, df/2, 'upper' );
end

%%

[chi2_info, chi2_labels] = dsp3.chi2_tabular_frequencies( ...
  use_counts, chi_labels', 'psth_epoch', 'psth_sig_counts', 'region' );

%%  plot significant counts

do_save = true;

pl = plotlabeled.make_common();
pl.bar_add_summary_values_as_text = false;
pl.bar_summary_text_format = '%0.2f';
pl.group_order = { 'm1_init_only', 'm2_init_only', 'both' };
pl.x_order = { 'bla', 'ofc', 'acc', 'dmpfc' };

props = counts ./ unit_counts .* 100;
[axs, inds] = pl.stackedbar( props, count_labels, 'region', 'psth_sig_counts', 'psth_epoch' );

for i = 1:numel(inds)
  I = inds{i};
  for j = 1:size(I, 1)
    prev_ct = 0;    
    for k = 1:size(I, 2)
      x = j;
      ct = counts(I{j, k});
      prop = props(I{j, k});
      y = prev_ct + prop * 0.5;
      prev_ct = prev_ct + prop;
      text( axs(i), x, y, sprintf('%d', ct) );
    end
  end
end

ylabel( axs(1), '% Sig' );

if ( do_save )
  shared_utils.plot.fullscreen( gcf );
  save_p = fullfile( bfw.dataroot, 'plots', 'interactive_psth', dsp3.datedir, 'sig_counts' );
  dsp3.req_savefig( gcf, save_p, count_labels, 'region' );
end

%%  post

unit_cats = {'unit_uuid', 'region', 'session', 'initiator', 'follower'};

unit_mask = fcat.mask( psth_labels ...
  , @find, {'solo-type', 'joint-type'} ...
);

[count_labels, unit_I] = keepeach( psth_labels', unit_cats, unit_mask );
num_consec_bins_sig = 3;
meets_criterion = false( numel(unit_I), 1 );

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  ind = unit_I{i};
  
  solo = find( psth_labels, 'solo-type', ind );
  joint = find( psth_labels, 'joint-type', ind );
  
  if ( isempty(solo) || isempty(joint) )
    continue;
  end
  
  t_ind = psth_t >= 0.5 & psth_t <= 1;
  t_mean_solo = nanmean( psth(solo, t_ind), 2 );
  t_mean_join = nanmean( psth(joint, t_ind), 2 );
  is_sig = ranksum( t_mean_solo, t_mean_join ) < 0.05;
  
%   test = @(x, y) ranksum(x, y) < 0.05;
%   tf = solo_vs_interactive( psth, solo, joint, test, num_consec_bins_sig );
%   
%   tf_ind = psth_t >= 0;
%   tf = tf & tf_ind;
  
  meets_criterion(i) = any( is_sig );  
end

%%

addsetcat( count_labels, 'interactive_is_sig', 'interactive_is_sig__false' );
setcat( count_labels, 'interactive_is_sig', 'interactive_is_sig__true', find(meets_criterion) );

[cts, ct_labels] = counts_of( count_labels, {'initiator', 'follower', 'region'}, {'interactive_is_sig'} );

unit_labs = keepeach( psth_labels', setdiff(unit_cats, {'initiator', 'follower'}), unit_mask );
[unit_labs, unit_I] = keepeach( unit_labs, 'region' );
unit_denom = cellfun( @numel, unit_I );

for i = 1:size(ct_labels, 1)
  reg = cellstr( ct_labels, 'region', i );
  unit_ind = find( unit_labs, reg );
  cts(i) = cts(i) / unit_denom(unit_ind);
end

%%

pl = plotlabeled.make_common();
ct_mask = find( ct_labels, 'interactive_is_sig__true' );
axs = pl.bar( cts(ct_mask), ct_labels(ct_mask), {'initiator', 'follower'}, {'interactive_is_sig'}, {'region'} );

%%

function plot_psth(psth, psth_labels, psth_t, event_res, time, event_inds, time_inds, unit_mask, varargin)

n_p = 40 * 0.01 / uniquetol( diff(psth_t) );

defaults = struct();
defaults.config = bfw.config.load();
defaults.add_error_lines = false;
defaults.smooth_func = @(x) smoothdata(x, 'movmean', n_p);
defaults.only_plot_sig = false;
defaults.do_save = false;
defaults.num_consec_bins_sig = 1;
defaults.unit_cats = { 'unit_uuid', 'region', 'session', 'initiator', 'follower' };
defaults.sig_test_func = @(x, y) ranksum(x, y) < 0.05;
defaults.add_smoothing = true;
defaults.stats_psth = psth;
defaults.stats_psth_t = psth_t;

params = shared_utils.general.parsestruct( defaults, varargin );

assert_ispair( psth, psth_labels );
assert( numel(psth_t) == size(psth, 2) );

stats_psth = params.stats_psth;
stats_psth_t = params.stats_psth_t;
assert_ispair( stats_psth, psth_labels );
assert( numel(stats_psth_t) == size(stats_psth, 2) );

unit_cats = params.unit_cats;
unit_I = findall( psth_labels, unit_cats, unit_mask );
num_consec_bins_sig = params.num_consec_bins_sig;

time_vs = time.time(:, 2);

do_save = params.do_save;
only_plot_sig = params.only_plot_sig;
smooth_func = params.smooth_func;
add_error_lines = params.add_error_lines;
fig = figure(1);

if ( params.add_smoothing )
  thicken_smooth_func = smooth_func;
else
  thicken_smooth_func = @identity;
end

pcats = union( unit_cats, {'initiator', 'follower'} );

save_p = fullfile( bfw.dataroot(params.config), 'plots/interactive_psth', dsp3.datedir );

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  init_I = findall( psth_labels, {'initiator', 'follower'}, unit_I{i} );
  shp = plotlabeled.get_subplot_shape( numel(init_I) );
  clf( fig );
  
  % Find axes limits
  [min_v, max_v] = psth_axis_limits( init_I, psth, psth_labels, thicken_smooth_func );
  
  for j = 1:numel(init_I)
    axes = subplot( shp(1), shp(2), j );
    cla( axes );
    
    ind = init_I{j};

    solo = find( psth_labels, 'solo-type', ind );
    joint = find( psth_labels, 'joint-type', ind );

    if ( isempty(solo) || isempty(joint) )
      continue;
    end

    test = params.sig_test_func;
    is_sig = solo_vs_interactive( stats_psth, solo, joint, test, num_consec_bins_sig );

    if ( only_plot_sig && ~any(is_sig) )
      continue;
    end

    psth_joint_event_inds = event_inds(joint);
    psth_joint_time_inds = time_inds(joint);

    psth_joint_event_portions = event_res.event_portions(psth_joint_event_inds, :);
    psth_joint_event_starts = event_res.event_starts(psth_joint_event_inds);
    psth_joint_event_times = event_inds_to_time( psth_joint_event_starts, psth_joint_time_inds, time_vs );

    psth_joint_portion_times = ...
      event_portions_to_time( psth_joint_event_portions, psth_joint_time_inds, time_vs );
    psth_joint_portion_times = ...
      event_relative_event_portions( psth_joint_event_times, psth_joint_portion_times );

    psth_keep = psth(ind, :);
    psth_labels_keep = prune( psth_labels(ind) );    

    pl = plotlabeled.make_common();
    pl.clear_figure = false;
    pl.get_axes_func = @(varargin) axes;
    pl.add_smoothing = params.add_smoothing;
    pl.smooth_func = smooth_func;
    pl.x = psth_t;
    pl.add_errors = add_error_lines;
    pl.y_lims = [min_v, max_v];
    
    [axs, line_hs, line_inds] = ...
      pl.lines( psth_keep, psth_labels_keep, 'interactive_event_type', pcats );

    assert( numel(axs) == 1 );
    hold( axs(1), 'on' );

    if ( any(is_sig) )
      y = max( get(axs(1), 'ylim') );
      plot( axs(1), stats_psth_t(is_sig), repmat(y, 1, sum(is_sig)), 'k*' );
    end

    add_event_histogram( axs(1), psth_joint_portion_times, 0.005 );
    thicken_sig_portions( ...
      axs(1), psth_t, psth_keep, is_sig, stats_psth_t, line_hs, line_inds, thicken_smooth_func );
  end
  
  if ( do_save )
    subdir_cats = { 'region' };
    subdir = strjoin( columnize(combs(psth_labels_keep, subdir_cats)), '_' );
    sig_prefix = sprintf( '%d_', sum(is_sig) );
    full_save_p = fullfile( save_p, subdir );
    
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, full_save_p, psth_labels_keep, unit_cats, sig_prefix );
  end
end

end

function [min_v, max_v] = psth_axis_limits(line_I, psth, psth_labels, smooth_func)

min_v = inf;
max_v = -inf;

for i = 1:numel(line_I)
  mean_inds = {find(psth_labels, 'solo-type', line_I{i}) ...
             , find(psth_labels, 'joint-type', line_I{i})};
  means = bfw.row_mean( psth, mean_inds );
  means = cat_expanded( 1 ...
    , arrayfun(@(x) smooth_func(means(x, :)), 1:size(means, 1), 'un', 0) );
  min_v = min(min_v, min(min(means, [], 1), [], 2));
  max_v = max(max_v, max(max(means, [], 1), [], 2));
end

assert( isfinite(min_v) && isfinite(max_v) );
expand = (max_v - min_v) * 0.1;
min_v = min_v - expand * 0.5;
max_v = max_v + expand * 0.5;

end

function tf = psth_permutation_test(x, y, n_iter, sig_thresh)

real_diff = abs( mean(x) - mean(y) );
nx = numel( x );

samp = [ x; y ];
pass = false( n_iter, 1 );

for i = 1:n_iter
  shuff = samp(randperm(numel(samp)));
  new_x = shuff(1:nx);
  new_y = shuff(nx+1:end);
  null_diff = abs( mean(new_x) - mean(new_y) );
  pass(i) = real_diff > null_diff;
end

tf = (sum(pass) / n_iter) > sig_thresh;

end

function event_ts = event_inds_to_time(event_inds, time_inds, time)

assert( numel(event_inds) == numel(time_inds) );
t = time(time_inds);

event_ts = nan( size(event_inds) );

for i = 1:numel(event_inds)
  ts = t{i};
  event_ts(i) = ts(event_inds(i));
end

end

function event_portions = event_portions_to_time(event_portions, time_inds, time)

assert( size(event_portions, 1) == numel(time_inds) );
t = time(time_inds);

for i = 1:size(event_portions, 1)
  ts = t{i};
  for j = 1:size(event_portions, 2)
    event_portions{i, j} = ts(event_portions{i, j});
  end
end

end

function thicken_sig_portions(ax, psth_t, data, is_sig, stats_t, line_hs, line_inds, smooth_func)

assert( size(data, 2) == numel(psth_t) );
assert( numel(is_sig) == numel(stats_t) );

sig_ts = stats_t(is_sig);
sig_inds = zeros( size(sig_ts) );

for i = 1:numel(sig_ts)
  [~, sig_ind] = min( abs(psth_t - sig_ts(i)) );
  assert( abs(psth_t(sig_ind) - sig_ts(i)) <= eps ...
    , 'No match between stats significant time point and psth time point.' );
  sig_inds(i) = sig_ind;
end

x_space = uniquetol( diff(psth_t) ) * 0.5;

for i = 1:numel(line_inds)
  for j = 1:numel(line_inds{i})
    mean_trace = smooth_func( nanmean(data(line_inds{i}{j}, :), 1) );
    line_h = line_hs{i}(j);
    line_color = get( line_h, 'color' );
    
    for k = 1:numel(sig_inds)
      sig_ind = sig_inds(k);      
      prev_ind = sig_ind - 1;
      next_ind = sig_ind + 1;

      curr_pt = mean_trace(sig_ind);
      hs = gobjects( 0, 0 );
      
      if ( prev_ind > 1 )
        prev_pt = mean_trace(prev_ind);
        curr_x = psth_t(sig_ind);
        prev_x = psth_t(prev_ind);
        dx = curr_x - prev_x;
        to_prev = prev_pt - curr_pt;
        frac = x_space / dx;
        p0 = curr_pt + to_prev * frac;
        hs(end+1) = plot( ax, [curr_x-x_space, curr_x], [p0, curr_pt], 'r' );
      end
      
      if ( next_ind <= numel(psth_t) )
        next_pt = mean_trace(next_ind);
        curr_x = psth_t(sig_ind);
        next_x = psth_t(next_ind);
        dx = next_x - curr_x;
        to_next = next_pt - curr_pt;
        frac = x_space / dx;
        p1 = curr_pt + to_next * frac;
        hs(end+1) = plot( ax, [curr_x, curr_x+x_space], [curr_pt, p1], 'r' );
      end      
      
      set( hs, 'linewidth', 4 );
      set( hs, 'color', line_color );
    end
  end
end

end

function add_event_histogram(ax, event_portions, rel_space_per_row)

y_lims = get( ax, 'ylim' );
x_lims = get( ax, 'xlim' );

space = diff( y_lims ) * rel_space_per_row;

for i = 1:size(event_portions, 1)
  y = y_lims(2) - (i-1) * space;
  
  colors = { 'r', 'g', 'b' };
  for j = 1:3
    portion = event_portions{i, j};
    portion(portion < x_lims(1) | portion > x_lims(2)) = [];
    plot( ax, portion, repmat(y, size(portion)), colors{j} );
  end
end

end

function out_tf = solo_vs_interactive(psth, solo_ind, interactive_ind, test, bin_crit)

psth_solo = psth(solo_ind, :);
psth_inter = psth(interactive_ind, :);

tf = false( 1, size(psth_solo, 2) );

for i = 1:size(psth_solo, 2)
  solo = psth_solo(:, i);
  inter = psth_inter(:, i);
  tf(i) = test( solo, inter );
end

%%  only retain significant sequences of at least `bin_crit` length

out_tf = false( size(tf) );
[islands, durs] = shared_utils.logical.find_islands( tf );
keep_islands = find( durs >= bin_crit );

for i = 1:numel(keep_islands)
  isle = islands(keep_islands(i));
  dur = durs(keep_islands(i));
  out_tf(isle:(isle+dur-1)) = true;
end

end

function [psth, psth_labels, bin_ts, all_event_inds, all_time_inds] = ...
  make_psth(events, spikes, time, min_t, max_t, bin_size)

psths = cell( numel(spikes.spike_times), 1 );
psth_labels = cell( size(psths) );
bin_ts = cell( size(psths) );
all_event_inds = cell( size(psths) );
all_time_inds = cell( size(psths) );

parfor i = 1:numel(spikes.spike_times)
  % For each cell.
  shared_utils.general.progress( i, numel(spikes.spike_times) );
  
  % Find the corresponding session.
  search_for = cellstr( spikes.labels, {'session'}, i );
  event_inds = find( events.labels, search_for );
  event_starts = events.event_starts(event_inds);
  [event_times, time_inds] = to_event_times( events.labels, event_inds, event_starts, time );
  
  spike_ts = spikes.spike_times{i};
  [psth, bin_t] = bfw.trial_psth( spike_ts, event_times, min_t, max_t, bin_size );
  
  psth_labels{i} = join( prune(events.labels(event_inds)), prune(spikes.labels(i)) );
  psths{i} = psth;
  bin_ts{i} = bin_t;
  all_event_inds{i} = event_inds;
  all_time_inds{i} = time_inds;
end

psth = vertcat( psths{:} );
psth_labels = vertcat( fcat, psth_labels{:} );
bin_ts = vertcat( bin_ts{:} );
all_event_inds = vertcat( all_event_inds{:} );
all_time_inds = vertcat( all_time_inds{:} );

assert_ispair( psth, psth_labels );
assert_ispair( all_event_inds, psth_labels );
assert_ispair( all_time_inds, psth_labels );

if ( ~isempty(bin_ts) )
  bin_ts = bin_ts(1, :);
end

end

function [event_times, match_t] = to_event_times(event_labels, event_inds, event_starts, time)

un_filenames = cellstr( event_labels, 'unified_filename', event_inds );
[~, match_t] = ismember( un_filenames, time.time(:, 1) );
assert( ~any(match_t == 0) );
times = time.time(match_t, 2);
event_times = arrayfun( @(event, time) time{1}(event), event_starts, times );

end

function event_portions = event_relative_event_portions(event_starts, event_portions)

assert( numel(event_starts) == size(event_portions, 1) );

for i = 1:size(event_portions, 1)
  for j = 1:size(event_portions, 2)
    event_portions{i, j} = event_portions{i, j} - event_starts(i);
  end
end

end

function cc_spike_labels = make_cc_spike_labels(src_spike_labels)

cc_spike_labels = src_spike_labels';
cc_inter_labels = bfw_cc_spike_unit_ids_to_cc_interactive_unit_ids( true );
cc_inter_label_keys = keys( cc_inter_labels );

cc_ns = fcat.parse( cellstr(cc_spike_labels, 'unit_uuid'), 'unit_uuid__' );
src_ns = fcat.parse( cellstr(src_spike_labels, 'unit_uuid'), 'unit_uuid__' );

cc_max = max( cc_ns );
src_max = max( src_ns );
next_id = max( cc_max, src_max ) + 1;

for i = 1:numel(cc_inter_label_keys)
  src_ind = find( cc_spike_labels, cc_inter_label_keys{i} );
  assert( numel(src_ind) == 1 );
  dest_uuid = cc_inter_labels(cc_inter_label_keys{i});
  dest_uuid_ind = find( cc_spike_labels, dest_uuid );
  
  if ( numel(dest_uuid_ind) == 1 )
    % cc's new unit id already exists, so we need to rename the existing
    % unit id to something distinct.
    replace_uuid = sprintf( 'unit_uuid__%d', next_id );
    assert( count(cc_spike_labels, replace_uuid) == 0 );
    
    setcat( cc_spike_labels, 'unit_uuid', replace_uuid, dest_uuid_ind );
    next_id = next_id + 1;
  else
    assert( isempty(dest_uuid_ind) );
  end
  
  setcat( cc_spike_labels, 'unit_uuid', dest_uuid, src_ind );
end

prune( cc_spike_labels );

end

function [summary_counts, summary_unit_counts, summary_labs] = ...
  count_significant_types(psth, psth_labels, psth_t, unit_mask, varargin)

defaults = struct();
defaults.denominator_unit_labels = [];

params = shared_utils.general.parsestruct( defaults, varargin );

assert_ispair( psth, psth_labels );
assert( numel(psth_t) == size(psth, 2) );

unit_cats = { 'unit_uuid', 'region', 'session' };

[per_unit_labs, unit_I] = keepeach( psth_labels', unit_cats, unit_mask );
epochs = { [0, 0.5], [0.5, 1] };
epoch_strs = { 'early', 'late' };
epoch_mean_psths = ...
  cellfun( @(x) nanmean(psth(:, psth_t >= x(1) & psth_t <= x(2)), 2), epochs, 'un', 0 );

summary_labs = keepeach( psth_labels', 'region', unit_mask );
repset( addcat(summary_labs, 'psth_epoch'), 'psth_epoch', {'early', 'late'} );
repset( addcat(summary_labs, 'psth_sig_counts'), 'psth_sig_counts', {'m1_init_only', 'm2_init_only', 'both'} );
summary_counts = zeros( size(summary_labs, 1), 1 );

if ( isempty(params.denominator_unit_labels) )
  [unit_count_I, unit_count_C] = findall( per_unit_labs, 'region' );
else
  [unit_count_I, unit_count_C] = findall( params.denominator_unit_labels, 'region' );
end

unit_counts = cellfun( @numel, unit_count_I );
summary_unit_counts = zeros( size(summary_counts) );

comb_inds = dsp3.numel_combvec( unit_I, epochs );
for i = 1:size(comb_inds, 2)  
  comb_ind = comb_inds(:, i);
  unit_ind = unit_I{comb_ind(1)};
  epoch_str = epoch_strs{comb_ind(2)};
  t_mean_psth = epoch_mean_psths{comb_ind(2)};
  
  if ( ~isempty(params.denominator_unit_labels) )
    search_in_denom = cellstr( ...
      per_unit_labs, strrep(unit_cats, 'unit_uuid', 'original_uuid'), comb_ind(1) );
    
    search_in_denom{1} = strrep( search_in_denom{1}, 'original_', '' );
    denom_ind = find( params.denominator_unit_labels, search_in_denom );
    
    if ( numel(denom_ind) == 0 )
      continue;
    end
  end
  
  rs_test = @(x, y) ranksum(x, y) < 0.05;
  test = @(x, y) conditional(@() isempty(x) || isempty(y), @() false, @() rs_test(x, y) );
  
  m1_init_ind = find( psth_labels, {'m1_initiated', 'm2_followed', 'joint-type'}, unit_ind );
  m2_init_ind = find( psth_labels, {'m2_initiated', 'm1_followed', 'joint-type'}, unit_ind );
  solo_ind = find( psth_labels, {'solo-type'}, unit_ind );
  
  [sig_m1_only, sig_m2_only, sig_both] = ...
    test_mean_level_significance( t_mean_psth, solo_ind, m1_init_ind, m2_init_ind, test );
  
  search_reg = cellstr( per_unit_labs, 'region', comb_ind(1) );
  search_epoch = epoch_str;
  
  is_sig = [sig_m1_only, sig_m2_only, sig_both];
  sig_strs = { 'm1_init_only', 'm2_init_only', 'both' };
  
  for j = 1:numel(sig_strs)
    summary_ind = find( summary_labs, [search_reg, search_epoch, sig_strs(j)] );
    assert( numel(summary_ind) == 1 );
    summary_counts(summary_ind) = summary_counts(summary_ind) + double(is_sig(j));
    
    count_ind = find( strcmp(unit_count_C, search_reg) );
    assert( numel(count_ind) == 1 );
    summary_unit_counts(summary_ind) = unit_counts(count_ind);
  end
end

end

function [sig_m1_init_only, sig_m2_init_only, sig_both] = ...
  test_mean_level_significance(psth, solo_ind, joint_ind_m1_init, joint_ind_m2_init, test)

assert( isvector(psth) );

solo = psth(solo_ind);
joint_m1_init = psth(joint_ind_m1_init);
joint_m2_init = psth(joint_ind_m2_init);

sig_m1_init = test( solo, joint_m1_init );
sig_m2_init = test( solo, joint_m2_init );

sig_both = sig_m1_init && sig_m2_init;

if ( ~sig_both )
  sig_m1_init_only = sig_m1_init;
  sig_m2_init_only = sig_m2_init;
else
  sig_m1_init_only = false;
  sig_m2_init_only = false;
end

end

function labels = randomize_unit_uuids(labels)

for i = 1:size(labels, 1)
  old_uuid = sprintf( 'original_%s', char(cellstr(labels, 'unit_uuid', i)) );  
  setcat( labels, 'unit_uuid', sprintf('unit_uuid__%s', shared_utils.general.uuid), i );
  addsetcat( labels, 'original_uuid', old_uuid, i );
end

prune( labels );

end

function spikes = keep_spikes(spikes, mask)

spikes.labels = prune( spikes.labels(mask) );
spikes.spike_times = spikes.spike_times(mask);

assert_ispair( spikes.spike_times, spikes.labels );

end

function event_res = load_cc_event_res(conf, time_files)

if ( nargin == 0 )
  conf = bfw.config.load();
end

outs = bfw_load_cc_eye_interactive_events( conf );
event_res = bfw_cc_interactive_events_to_event_res( ...
  outs.indices, outs.times, outs.labels, time_files );

end