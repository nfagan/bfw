function modulation_index_vs_decoding_performance(rc, rc_labels, rc_mask, gc, gc_labels, gc_mask, varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.lda_iters = 100;
defaults.lda_holdout = 0.25;
defaults.rng_seed = [];
defaults.abs_modulation_index = false;

params = bfw.parsestruct( defaults, varargin );

assert_ispair( rc, rc_labels );
assert_ispair( gc, gc_labels );

rc_mask = get_base_reward_mask( rc_labels, get_base_mask(rc_labels, rc_mask) );
gc_mask = get_base_gaze_mask( gc_labels, get_base_mask(gc_labels, gc_mask) );

rc_each = { 'event-name' };
gc_each = {};

rc_I = findall_or_one( rc_labels, rc_each, rc_mask );
gc_I = findall_or_one( gc_labels, gc_each, gc_mask );

gc_pairs = gaze_roi_pairs();
rl_pairs = reward_level_pairs();

each_combs = dsp3.numel_combvec( rc_I, gc_I, gc_pairs, rl_pairs );

for idx = 1:4
  fprintf( '\n %d of %d', idx, 2 );
  
  for i = 1:size(each_combs, 2)
    fprintf( '\n\t %d of %d', i, size(each_combs, 2) );
    
    rc_ind = rc_I{each_combs(1, i)};
    gc_ind = gc_I{each_combs(2, i)};
    gc_pair = gc_pairs{each_combs(3, i)};
    rl_pair = rl_pairs{each_combs(4, i)};
    
    if ( idx == 3 && each_combs(4, i) ~= 1 )
      % gaze <-> gaze does not depend on reward pairs.
      continue;
    elseif ( idx == 4 && each_combs(3, i) ~= 1 )
      % reward <-> reward does not depend on gaze pairs.
      continue;
    end
    
    rc_aggregate = make_aggregate( rc, rc_labels, rc_ind, rl_pair );
    gc_aggregate = make_aggregate( gc, gc_labels, gc_ind, gc_pair );
    
    if ( idx == 1 )
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( rc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( gc_aggregate );
      
      x_is = 'Reward';
      y_is = 'Gaze';
    elseif ( idx == 2 )
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( gc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( rc_aggregate );
      
      x_is = 'Gaze';
      y_is = 'Reward';
      
    elseif ( idx == 3 )
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( gc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( gc_aggregate );
      
      x_is = 'Gaze';
      y_is = 'Gaze';
    else
      [mod_source, mod_labels, mod_mask, mod_pair] = destructure_aggregate( rc_aggregate );
      [decode_source, decode_labels, decode_mask, decode_pair] = destructure_aggregate( rc_aggregate );
      
      x_is = 'Reward';
      y_is = 'Reward';
    end
    
    prefix = sprintf( '%d-%d_', idx, i );

    try
      [modulation_index, decode_performance, pair_labels] = ...
        binary_modulation_index_vs_binary_decoding( mod_source, mod_labels, mod_mask ...
          , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, params );

      plot_scatters( modulation_index, decode_performance, pair_labels, x_is, y_is, prefix, params );
    catch err
      warning( err.message );
    end
  end
end

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

function plot_scatters(modulation_index, decode_performance, pair_labels, x_is, y_is, prefix, params)

pl = plotlabeled.make_common();
gcats = {};
pcats = { 'roi', 'event-name', 'region' };

non_nan = ~isnan( modulation_index ) & ~isnan( decode_performance );
mod_index = modulation_index(non_nan);
decode_perf = decode_performance(non_nan);

if ( params.abs_modulation_index )
  mod_index = abs( mod_index );
end

plt_labs = addcat( prune(pair_labels(find(non_nan))), pcats );

[axs, ids] = pl.scatter( mod_index, decode_perf, plt_labs, gcats, pcats );
[hs, store_stats] = pl.scatter_addcorr( ids, mod_index, decode_perf );

xlabel( axs(1), sprintf('%s modulation index', x_is) );
ylabel( axs(1), sprintf('%s decoding performance', y_is) );

if ( params.do_save )
  prefix = sprintf( '%s%s', prefix, params.prefix );
  shared_utils.plot.fullscreen( gcf );
  save_p = get_plot_p( params, 'scatters' );
  dsp3.req_savefig( gcf, save_p, pair_labels, [gcats, pcats], prefix );
end

end

function [mod_indices, decode_perf, pair_labels] = binary_modulation_index_vs_binary_decoding(mod_source, mod_labels, mod_mask ...
  , decode_source, decode_labels, decode_mask, mod_pair, decode_pair, params)

assert_ispair( mod_source, mod_labels );
assert_ispair( decode_source, decode_labels );

[mod_unit_I, mod_unit_ids] = findall( mod_labels, {'unit_uuid', 'channel', 'region'}, mod_mask );

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
    mean_a = nanmean( mod_source(mod_ind_a) );
    mean_b = nanmean( mod_source(mod_ind_b) );
    mod_indices(i) = (mean_a - mean_b) ./ (mean_a + mean_b);

    subset_decode = decode_source(decode_ind);
    subset_levels = decode_levels(decode_ind);

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
  
partition = cvpartition( num_trials, 'HoldOut', params.lda_holdout );

train_levels = subset_levels(partition.training);
test_levels = subset_levels(partition.test);

train_counts = subset_counts(partition.training);
test_counts = subset_counts(partition.test);

model = fitcdiscr( train_counts, train_levels, 'discrimtype', 'pseudolinear' );

predicted = predict( model, test_counts );
p_corr = pnz( predicted == test_levels );

end

function mask = get_base_gaze_mask(labels, mask)

mask = fcat.mask( labels, mask ...
  , @findor, {'nonsocial_object', 'face', 'eyes_nf'} ...
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

rois = { ...
  {'face', 'eyes_nf'} ...
  , {'nonsocial_object', 'face'} ...
  , {'nonsocial_object', 'eyes_nf'} ...
};

end

function plot_p = get_plot_p(params, varargin)

plot_p = fullfile( bfw.dataroot(params.config), 'plots', 'cs_sens_vs_lda' ...
  , dsp3.datedir, 'modulation_index_vs_decoding', params.base_subdir, varargin{:} );

end