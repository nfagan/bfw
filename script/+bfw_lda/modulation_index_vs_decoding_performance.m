function modulation_index_vs_decoding_performance(rc, rc_labels, rc_mask, gc, gc_labels, gc_mask, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.lda_iters = 100;
defaults.lda_holdout = 0.25;
defaults.rng_seed = [];
defaults.abs_modulation_index = false;
defaults.kinds = 'all';
defaults.a_is = 'reward';
defaults.b_is = 'gaze';
defaults.a_type = 'spikes';
defaults.b_type = 'spikes';
defaults.additional_each = {};
defaults.permutation_test = false;
defaults.permutation_test_iters = 1;
defaults.plot = true;
defaults.use_multi_regression = false;

params = bfw.parsestruct( defaults, varargin );

assert_ispair( rc, rc_labels );
assert_ispair( gc, gc_labels );

rc_mask = get_mask_a( rc_labels, rc_mask, params );
gc_mask = get_mask_b( gc_labels, gc_mask, params );

rc_each = ternary( strcmp(params.a_is, 'reward'), {'event-name'}, {} );
gc_each = ternary( strcmp(params.b_is, 'gaze'), {}, {'event-name'} );

rc_I = findall_or_one( rc_labels, rc_each, rc_mask );
gc_I = findall_or_one( gc_labels, gc_each, gc_mask );

rl_pairs = ternary( strcmp(params.a_is, 'reward'), reward_level_pairs(), gaze_roi_pairs() );
gc_pairs = ternary( strcmp(params.b_is, 'gaze'), gaze_roi_pairs(), reward_level_pairs() );

if ( ~strcmp(params.a_is, params.b_is) )
  each_combs = dsp3.numel_combvec( rc_I, gc_I, gc_pairs, rl_pairs );
else
  each_combs = dsp3.numel_combvec( rc_I, gc_I, rl_pairs );
end

kind_set = get_kind_indices( params.kinds );

for idx = kind_set
  fprintf( '\n %d of %d', idx - min(kind_set) + 1, numel(kind_set) );
  
  for i = 1:size(each_combs, 2)
    fprintf( '\n\t %d of %d', i, size(each_combs, 2) );
    
    rc_ind = rc_I{each_combs(1, i)};
    gc_ind = gc_I{each_combs(2, i)};
    gc_pair = gc_pairs{each_combs(3, i)};
    
    if ( ~strcmp(params.a_is, params.b_is) )
      rl_pair = rl_pairs{each_combs(4, i)};
    else
      rl_pair = gc_pair;
    end
    
    if ( idx == 3 && each_combs(4, i) ~= 1 )
      % gaze <-> gaze does not depend on reward pairs.
      continue;
    elseif ( idx == 4 && each_combs(3, i) ~= 1 )
      % reward <-> reward does not depend on gaze pairs.
      continue;
    end
    
    if ( strcmp(params.a_is, params.b_is) && ~all(strcmp(gc_pair, rl_pair)) )
      fprintf( '\n Skipping unlike pair: (%s), (%s)', strjoin(gc_pair, ','), strjoin(rl_pair, ',') );
      continue;
    end
    
    rc_aggregate = make_aggregate( rc, rc_labels, rc_ind, rl_pair );
    gc_aggregate = make_aggregate( gc, gc_labels, gc_ind, gc_pair );
    
    make_axis_str = @(kind, type) sprintf( '%s %s', kind, type );
    
    if ( idx == 1 )
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( rc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( gc_aggregate );
      
      x_is = make_axis_str( params.a_is, params.a_type );
      y_is = make_axis_str( params.b_is, params.b_type );
    elseif ( idx == 2 )
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( gc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( rc_aggregate );
      
      x_is = make_axis_str( params.b_is, params.b_type );
      y_is = make_axis_str( params.a_is, params.a_type );
    elseif ( idx == 3 )
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( gc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( gc_aggregate );
      
      x_is = make_axis_str( params.b_is, params.b_type );
      y_is = make_axis_str( params.b_is, params.b_type );
    else
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( rc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( rc_aggregate );
      
      x_is = make_axis_str( params.a_is, params.a_type );
      y_is = make_axis_str( params.a_is, params.a_type );
    end
    
    prefix = sprintf( '%d-%d_', idx, i );

    try
      do_shuffle = false;
      
      [modulation_index, decode_performance, pair_labels] = ...
        binary_modulation_index_vs_binary_decoding( mod_source, mod_labels, mod_mask ...
          , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, do_shuffle, params );

      if ( params.plot )
        plot_summary_bars( modulation_index, decode_performance, pair_labels, x_is, y_is, prefix, params );
        plot_scatters( modulation_index, decode_performance, pair_labels, x_is, y_is, prefix, params );
      end
      
      if ( params.permutation_test )
        real_results = struct();
        real_results.modulation_index = modulation_index;
        real_results.decode_performance = decode_performance;
        real_results.pair_labels = pair_labels';
        
        permutation_test( real_results, mod_source, mod_labels, mod_mask ...
          , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, prefix, x_is, y_is, params );
      end
    catch err
      warning( err.message );
    end
  end
end

end

function permutation_test(real_results, mod_source, mod_labels, mod_mask ...
  , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, prefix ...
  , x_is, y_is, params)

corr_each = union( {'roi', 'event-name', 'region'}, params.additional_each );

real_corr_results = correlate_mod_index_decode_performance( ...
  real_results.modulation_index, real_results.decode_performance, real_results.pair_labels', corr_each ...
);

real_corr_stats = extract_correlation_stats( real_corr_results );

shuffled_indices = cell( params.permutation_test_iters, 1 );
shuffled_perf = cell( size(shuffled_indices) );
shuffled_labels = cell( size(shuffled_indices) );
shuffled_corr_stats = cell( size(shuffled_indices) );
shuffled_corr_labels = cell( size(shuffled_indices) );
shuffled_is_sig = cell( size(shuffled_indices) );

for i = 1:params.permutation_test_iters
  [modulation_index, decode_performance, pair_labels] = ...
    binary_modulation_index_vs_binary_decoding( mod_source, mod_labels, mod_mask ...
          , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, true, params );
        
  assert( pair_labels == real_results.pair_labels, 'Shuffled + real labels mismatch.' );
        
  perm_cat = 'permutation_iteration';
  addsetcat( pair_labels, perm_cat, sprintf('%s__%d', perm_cat, i) );
  
  shuffled_indices{i} = modulation_index;
  shuffled_perf{i} = decode_performance;
  shuffled_labels{i} = pair_labels;
  
  shuffled_corr_results = correlate_mod_index_decode_performance( ...
    modulation_index, decode_performance, pair_labels', corr_each ...
  );

  tmp_shuffled_stats = extract_correlation_stats( shuffled_corr_results );

  shuffled_corr_stats{i} = tmp_shuffled_stats;
  shuffled_corr_labels{i} = shuffled_corr_results.corr_labels;
  shuffled_is_sig{i} = check_shuffled_correlations_are_significant( real_corr_stats, tmp_shuffled_stats );
end

shuffled_indices = vertcat( shuffled_indices{:} );
shuffled_perf = vertcat( shuffled_perf{:} );
shuffled_labels = vertcat( fcat(), shuffled_labels{:} );
shuffled_corr_stats = vertcat( shuffled_corr_stats{:} );
shuffled_corr_labels = vertcat( fcat(), shuffled_corr_labels{:} );
shuffled_is_sig = sum_many( shuffled_is_sig{:} );

p_real = shuffled_is_sig / params.permutation_test_iters;
p_real(any(isnan(real_corr_stats), 2)) = nan;

if ( params.do_save )
  save_permutation_test_results( p_real, real_corr_results.labels, prefix, x_is, y_is, params );
end

end

function save_permutation_test_results(p_real, labels, prefix, x_is, y_is, params)

prefix = sprintf( '%s%s', prefix, params.prefix );

if ( isempty(params.additional_each) )
  save_p = get_plot_p( params, 'scatters', sprintf('%s_%s', x_is, y_is), 'stats' );
  use_prefix = prefix;
else
  save_p = get_plot_p( params, 'scatters', sprintf('%s_%s', x_is, y_is), prefix, 'stats' );
  use_prefix = '';
end

req_writetable(tbl, p, labs, cats, use_prefix, ext)

end

function is_sig = check_shuffled_correlations_are_significant(real_stats, shuffled_stats)

is_sig = zeros( size(real_stats, 1), 1 );

for i = 1:size(real_stats, 1)
  real_r = real_stats(i, 1);
  shuff_r = shuffled_stats(i, 1);
  
  if ( isnan(real_r) || isnan(shuff_r) )
    continue;
  end
  
  sign_real = sign( real_r );
  
  if ( sign_real == -1 )
    is_sig(i) = double( shuff_r < real_r );
  else
    is_sig(i) = double( shuff_r > real_r );
  end
end

end

function stats = extract_correlation_stats(corr_results)

stats = eachcell( @(x) [x.rho, x.p], corr_results.corr_tables );
stats = vertcat( stats{:} );

end

function results = correlate_mod_index_decode_performance(modulation_index, decode_performance, labels, each)

results = dsp3.corr( modulation_index, decode_performance, labels, each ...
  , 'corr_inputs', {'rows', 'complete'} ...
);

end

function rc_mask = get_mask_a(rc_labels, rc_mask, params)

if ( strcmp(params.a_is, 'reward') )
  rc_mask = get_base_reward_mask( rc_labels, get_base_mask(rc_labels, rc_mask) );
else
  rc_mask = get_base_gaze_mask( rc_labels, get_base_mask(rc_labels, rc_mask) );
end

end

function gc_mask = get_mask_b(gc_labels, gc_mask, params)

if ( strcmp(params.b_is, 'gaze') )
  gc_mask = get_base_gaze_mask( gc_labels, get_base_mask(gc_labels, gc_mask) );
else
  gc_mask = get_base_reward_mask( gc_labels, get_base_mask(gc_labels, gc_mask) );
end

end

function inds = get_kind_indices(kinds)

kinds = cellstr( kinds );

if ( numel(kinds) == 1 && strcmp(kinds, 'all') )
  inds = 1:4;
  return
end

inds = [];

if ( ismember('a/b', kinds) ), inds(end+1) = 1; end
if ( ismember('b/a', kinds) ), inds(end+1) = 2; end
if ( ismember('b/b', kinds) ), inds(end+1) = 3; end
if ( ismember('a/a', kinds) ), inds(end+1) = 4; end

end

function [counts, labels, mask, pair] = destructure_aggregate(aggregate)

counts = aggregate.counts;
labels = aggregate.labels;
mask = aggregate.mask;
pair = aggregate.pair;

end

function aggregate = make_aggregate(counts, labels, mask, pair)

aggregate = struct();
aggregate.counts = counts;
aggregate.labels = labels;
aggregate.mask = mask;
aggregate.pair = pair;

end

function plot_summary_bars(modulation_index, decode_performance, pair_labels, x_is, y_is, prefix, params)

non_nan = ~isnan( modulation_index ) & ~isnan( decode_performance );
fig_I = findall_or_one( pair_labels, {}, find(non_nan) );

xcats = params.additional_each;
gcats = {'region'};
pcats = {'roi', 'event-name'};

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.y_lims = [0, 1];

  decode_perf = decode_performance(fig_I{i});
  plt_labs = addcat( prune(pair_labels(fig_I{i})), [pcats, gcats, xcats] );

  axs = pl.bar( decode_perf, plt_labs, xcats, gcats, pcats );
  ylabel( axs(1), sprintf('%s decoding performance', y_is) );

  if ( params.do_save )
    prefix = sprintf( '%s%s', prefix, params.prefix );
    shared_utils.plot.fullscreen( gcf );
    
    if ( isempty(params.additional_each) )
      save_p = get_plot_p( params, 'bars', sprintf('%s_%s', x_is, y_is) );
      dsp3.req_savefig( gcf, save_p, plt_labs, [gcats, pcats], prefix );
    else
      save_p = get_plot_p( params, 'bars', sprintf('%s_%s', x_is, y_is), prefix );
      dsp3.req_savefig( gcf, save_p, plt_labs, [gcats, pcats] );
    end
  end
end

end

function plot_scatters(modulation_index, decode_performance, pair_labels, x_is, y_is, prefix, params)

non_nan = ~isnan( modulation_index ) & ~isnan( decode_performance );
fig_I = findall_or_one( pair_labels, params.additional_each, find(non_nan) );

for i = 1:numel(fig_I)
  pl = plotlabeled.make_common();
  pl.y_lims = [0, 1];

  gcats = {};
  pcats = union( {'roi', 'event-name', 'region'}, params.additional_each );

  mod_index = modulation_index(fig_I{i});
  decode_perf = decode_performance(fig_I{i});

  if ( params.abs_modulation_index )
    mod_index = abs( mod_index );
  end

  plt_labs = addcat( prune(pair_labels(fig_I{i})), pcats );

  [axs, ids] = pl.scatter( mod_index, decode_perf, plt_labs, gcats, pcats );
  darken_scatters( axs );
  
  xlabel( axs(1), sprintf('%s modulation index', x_is) );
  ylabel( axs(1), sprintf('%s decoding performance', y_is) );

  if ( params.abs_modulation_index )
    shared_utils.plot.set_xlims( axs, [0, 1] );
  else
    shared_utils.plot.set_xlims( axs, [-1, 1] );
  end
  
  if ( ~params.use_multi_regression )
    [hs, store_stats] = pl.scatter_addcorr( ids, mod_index, decode_perf );
  else
    multi_regress( ids, mod_index, decode_perf );
  end

  if ( params.do_save )
    prefix = sprintf( '%s%s', prefix, params.prefix );
    shared_utils.plot.fullscreen( gcf );
    
    if ( isempty(params.additional_each) )
      save_p = get_plot_p( params, 'scatters', sprintf('%s_%s', x_is, y_is) );
      dsp3.req_savefig( gcf, save_p, plt_labs, [gcats, pcats], prefix );
    else
      save_p = get_plot_p( params, 'scatters', sprintf('%s_%s', x_is, y_is), prefix );
      dsp3.req_savefig( gcf, save_p, plt_labs, [gcats, pcats] );
    end
  end
end

end

function multi_regress(ids, mod_index, decode_perf)

subset_pre0 = find( mod_index < 0 );
subset_post0 = find( mod_index >= 0 );

for i = 1:numel(ids)
  ind0 = intersect( ids(i).index, subset_pre0 );
  ind1 = intersect( ids(i).index, subset_post0 );
  
  if ( isempty(ind0) )
    lm0 = [];
  else
    lm0 = fitlm( mod_index(ind0), decode_perf(ind0) );
  end
  
  if ( isempty(ind1) )
    lm1 = [];
  else
    lm1 = fitlm( mod_index(ind1), decode_perf(ind1) );
  end
  
  [beta0, intercept0, p0] = linear_model_coeffs( lm0 );
  [beta1, intercept1, p1] = linear_model_coeffs( lm1 );
  
  ax = ids(i).axes;
  xtick = get( ax, 'xtick' );
  hold( ax, 'on' );
  
  if ( ~isnan(beta0) )
    tick0 = xtick(xtick < 0);
    y0 = polyval( [beta0, intercept0], tick0 );
    
    plot( ax, tick0, y0 );
    text( ax, max(tick0), min(y0), sprintf('B = %0.2f; p = %0.2f', beta0, p0) );
  end
  
  if ( ~isnan(beta1) )
    tick1 = xtick(xtick >= 0);
    y1 = polyval( [beta1, intercept1], tick1 );
    
    plot( ax, tick1, y1 );
    text( ax, max(tick1), max(y1), sprintf('B = %0.2f; p = %0.2f', beta1, p1) );
  end
end

end

function [beta, intercept, p] = linear_model_coeffs(model)

if ( isempty(model) )
  beta = nan;
  p = nan;
  intercept = nan;
else
  beta = model.Coefficients.Estimate(2);
  p = model.Coefficients.pValue(2);
  intercept = model.Coefficients.Estimate(1);
end

end

function darken_scatters(axs)

scatters = findobj( axs, 'type', 'scatter' );
new_color = [0, 0, 0.9];
new_size = 4;

for i = 1:numel(scatters)
  c_data = repmat( new_color, rows(scatters(i).CData), 1 );
  set( scatters(i), 'CData', c_data );
end

set( scatters, 'LineWidth', new_size );

end

function [mod_indices, decode_perf, pair_labels] = binary_modulation_index_vs_binary_decoding(mod_source, mod_labels, mod_mask ...
  , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, shuffle, params)

assert_ispair( mod_source, mod_labels );
assert_ispair( decode_source, decode_labels );

mod_each = union( {'unit_uuid', 'channel', 'region'}, params.additional_each );
[mod_unit_I, mod_unit_ids] = findall( mod_labels, mod_each, mod_mask );

mod_indices = nan( size(mod_unit_I) );
decode_perf = nan( size(mod_unit_I) );
pair_labels = cell( size(mod_unit_I) );

decode_levels = nan( size(decode_source) );
decode_levels(find(decode_labels, decode_pair{1})) = 0;
decode_levels(find(decode_labels, decode_pair{2})) = 1;

if ( ~isempty(params.rng_seed) )
  prev_rng_state = rng( params.rng_seed );
end

parfor i = 1:numel(mod_unit_I)
  mod_ind_a = find( mod_labels, mod_pair{1}, mod_unit_I{i} );
  mod_ind_b = find( mod_labels, mod_pair{2}, mod_unit_I{i} );
  mod_ind = sort( [mod_ind_a; mod_ind_b] );
  
  decode_ind = find( decode_labels, [decode_pair, mod_unit_ids(:, i)'], decode_mask );  
  
  if ( ~isempty(decode_ind) && ~isempty(mod_ind_a) && ~isempty(mod_ind_b) )
    if ( shuffle )
      [mod_ind_a, mod_ind_b] = shuffle_modulation_indices( mod_ind_a, mod_ind_b );
    end
    
    mean_a = nanmean( mod_source(mod_ind_a) );
    mean_b = nanmean( mod_source(mod_ind_b) );
    mod_indices(i) = (mean_b - mean_a) ./ (mean_a + mean_b);

    subset_decode = decode_source(decode_ind);
    subset_levels = decode_levels(decode_ind);
    
    if ( shuffle )
      subset_levels = array_shuffle( subset_levels );
    end

    decode_perf(i) = lda( subset_decode, subset_levels, params );
  end
  
  if ( isempty(decode_ind) )
    decode_labs = fcat.with( getcats(decode_labels), 1 );
  else
    decode_labs = append1( fcat(), decode_labels, decode_ind );
  end
  
  if ( isempty(mod_ind) )
    mod_labs = fcat.with( getcats(mod_labels), 1 );
  else
    mod_labs = append1( fcat(), mod_labels, mod_ind );
  end
  
  pair_labels{i} = join( mod_labs, decode_labs );
end

pair_labels = vertcat( fcat(), pair_labels{:} );

try_set_pair_category( mod_labels, pair_labels, mod_pair );
try_set_pair_category( decode_labels, pair_labels, decode_pair );

if ( ~isempty(params.rng_seed) )
  rng( prev_rng_state );
end

end

function out = array_shuffle(a)

out = a(randperm(numel(a)));

end

function [out_a, out_b] = shuffle_modulation_indices(a, b)

num_a = numel( a );

tot = [ a; b ];
tot = array_shuffle( tot );

out_a = tot(1:num_a);
out_b = tot(num_a+1:end);

end

function try_set_pair_category(source_labels, dest_labels, pair)

if ( ~ischar(pair{1}) || ~ischar(pair{2}) || ~all(haslab(source_labels, pair)) )
  return
end

cat_a = whichcat( source_labels, pair{1} );
cat_b = whichcat( source_labels, pair{2} );

if ( strcmp(cat_a, cat_b) )
  setcat( dest_labels, cat_a, sprintf('%s/%s', pair{1}, pair{2}) );
end

end

function p_corr = lda(subset_counts, subset_levels, params)

num_trials = numel( subset_counts );
  
try
  partition = cvpartition( num_trials, 'HoldOut', params.lda_holdout );
catch err
  warning( err.message );
  p_corr = nan;
  return;
end

train_levels = subset_levels(partition.training);
test_levels = subset_levels(partition.test);

train_counts = subset_counts(partition.training);
test_counts = subset_counts(partition.test);

model = fitcdiscr( train_counts, train_levels, 'discrimtype', 'pseudolinear' );

predicted = predict( model, test_counts );
p_corr = pnz( predicted == test_levels );

end

function mask = get_base_gaze_mask(labels, mask)

rois = { 'nonsocial_object', 'face', 'eyes_nf', 'face_non_eyes' ...
  , 'nonsocial_object_eyes_nf_matched' };

mask = fcat.mask( labels, mask ...
  , @findor, rois ...
);

end

function mask = get_base_reward_mask(labels, mask)

mask = fcat.mask( labels, mask ...
  , @findnone, bfw.nan_reward_level() ...
  , @find, 'no-error' ...
);

end

function mask = get_base_mask(labels, apply_to)

mask = fcat.mask( labels, apply_to ...
  , @findnone, bfw.nan_unit_uuid() ...
);

end

function levels = reward_level_pairs()

levels = { ...
  {'reward-1', 'reward-3'} ...
};

end

function rois = gaze_roi_pairs()

% rois = { ...
%     {'face_non_eyes', 'eyes_nf'} ...
%   , {'nonsocial_object', 'face_non_eyes'} ...
%   , {'nonsocial_object', 'eyes_nf'} ...
%   , {'nonsocial_object_eyes_nf_matched', 'eyes_nf'} ...
%   , {'nonsocial_object', 'face'} ...
% };

rois = { ...
    {'face_non_eyes', 'eyes_nf'} ...
  , {'nonsocial_object_eyes_nf_matched', 'eyes_nf'} ...
  , {'nonsocial_object', 'face'} ...
};

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir, 'modulation_index_vs_decoding', params.base_subdir, varargin{:} );

end