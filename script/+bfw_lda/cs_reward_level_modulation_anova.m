function cs_reward_level_modulation_anova(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.reward_counts = [];
defaults.targ_t = [0.05, 0.4];
defaults.base_t = [0, 0.15];
defaults.targ_event = 'cs_presentation';
defaults.base_event = 'fixation';
defaults.lda_holdout = 0.25;
defaults.lda_iters = 1e2;
defaults.lda_rng_seed = [];
defaults.is_normalized = false;
defaults.mask_func = @(labels, varargin) rowmask( labels );
defaults.min_trials_per_condition = Inf;

params = bfw.parsestruct( defaults, varargin );

reward_counts = params.reward_counts;

if ( isempty(reward_counts) )
  reward_counts = bfw_get_cs_reward_response( ...
      'event_names', {params.targ_event, params.base_event} ...
    , 'look_back', -0.2 ...
    , 'look_ahead', 1 ...
    , 'is_firing_rate', false ...
    , 'include_rasters', false ...
  );
end

% decode_small_large( reward_counts, params );
% compare_baseline( reward_counts, params );
reward_level_regression( reward_counts, params );
compare_small_large( reward_counts, params );
reward_level_anova( reward_counts, params );

end

function decode_small_large(reward_counts, params)

counts = reward_counts.psth;
labs = reward_counts.labels';
targ_event = params.targ_event;

[t_ind, ~] = get_time_indices( reward_counts, params, params.targ_event );

mask = intersect( get_base_mask(labs), params.mask_func(labs, counts, targ_event) );
[targ_counts, targ_labs] = get_target_counts( counts, labs, targ_event, mask, t_ind );

reward_levels = fcat.parse( cellstr(targ_labs, 'reward-level'), 'reward-' );

each = { 'unit_uuid', 'channel', 'region' };
[decode_labs, each_I] = keepeach( targ_labs', each );

ps = zeros( numel(each_I), 1 );

if ( ~isempty(params.lda_rng_seed) )
  old_rng_state = rng( params.lda_rng_seed );
end

parfor i = 1:numel(each_I)
  subset_ind = each_I{i};
  subset_counts = targ_counts(subset_ind);
  subset_levels = reward_levels(subset_ind);
  
  real_p_corr = lda( subset_counts, subset_levels, params );
  shuff_p_corr = zeros( params.lda_iters, 1 );
  
  for j = 1:params.lda_iters
    shuff_levels = subset_levels(randperm(numel(subset_levels)));
    
    shuff_p_corr(j) = lda( subset_counts, shuff_levels, params );
  end
  
  if ( real_p_corr < 0.5 )
    ps(i) = 1 - sum( real_p_corr < shuff_p_corr ) / params.lda_iters;
  else
    ps(i) = 1 - sum( real_p_corr > shuff_p_corr ) / params.lda_iters;
  end
end

[percs_tbl, counts_tbl] = make_summary_tables( ps < 0.05, decode_labs );

if ( params.do_save )
  save_spec = 'region';
  save_p = get_save_p( params, 'small_vs_large_lda' );
  save_summary_tables( percs_tbl, counts_tbl, save_p, decode_labs, save_spec );
end

if ( ~isempty(params.lda_rng_seed) )
  rng( old_rng_state );
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

function compare_small_large(reward_counts, params)

labs = reward_counts.labels';

[event_I, event_C] = findall( labs, 'event-name', find(labs, params.targ_event) );
is_sig = cell( size(event_I) );

for idx = 1:numel(event_I)
  targ_event = event_C{idx};
  
  counts = reward_counts.psth;
  labs = reward_counts.labels';
  
  [t_ind, base_t_ind] = get_time_indices( reward_counts, params, targ_event );

  kept_unit_I = find_units_with_at_least_n_reps( reward_counts, params );
  mask = intersect( get_base_mask(labs), params.mask_func(labs, counts, targ_event) );
  mask = intersect( mask, kept_unit_I );

  [targ_counts, targ_labs] = get_target_counts( counts, labs, targ_event, mask, t_ind );

  if ( params.is_normalized )
    base_ind = find( labs, params.base_event, mask );
    assert( numel(base_ind) == numel(targ_counts) );
    
    base_counts = nanmean( counts(base_ind, base_t_ind), 2 );
    targ_counts = targ_counts - base_counts;
  end

  each = { 'unit_uuid', 'channel', 'region' };

  stat_outs = dsp3.ranksum( targ_counts, targ_labs, each, 'reward-1', 'reward-3' );

  ps = cellfun( @(x) x.p, stat_outs.rs_tables );
  is_sig{idx} = ps < 0.05;
end

is_sig = or_many( is_sig{:} );

[percs_tbl, counts_tbl] = make_summary_tables( is_sig, stat_outs.rs_labels );

if ( params.do_save )
  save_spec = 'region';
  save_p = get_save_p( params, 'small_vs_large' );
  save_summary_tables( percs_tbl, counts_tbl, save_p, stat_outs.rs_labels, save_spec );
end

end

function compare_baseline(reward_counts, params)

[t_ind, base_t_ind] = get_time_indices( reward_counts, params );

counts = reward_counts.psth;
labs = reward_counts.labels';

base_ind = find( labs, params.base_event );
base_counts = nanmean( counts(base_ind, base_t_ind), 2 );

targ_ind = find( labs, params.targ_event );
targ_counts = nanmean( counts(targ_ind, t_ind), 2 );

mask = intersect( get_base_mask(labs), params.mask_func(labs, counts, params.targ_event) );

counts = zeros( rows(counts), 1 );
counts(base_ind) = base_counts;
counts(targ_ind) = targ_counts;

each = { 'unit_uuid', 'channel', 'region' };

stat_outs = dsp3.ranksum( counts, labs, each, params.targ_event, params.base_event ...
  , 'mask', mask ...
);

ps = cellfun( @(x) x.p, stat_outs.rs_tables );
is_sig = ps < 0.05;

[percs_tbl, counts_tbl] = make_summary_tables( is_sig, stat_outs.rs_labels );

if ( params.do_save )
  save_spec = 'region';
  save_p = get_save_p( params, 'any_reward_vs_baseline' );
  save_summary_tables( percs_tbl, counts_tbl, save_p, stat_outs.rs_labels, save_spec );
end

end

function reward_level_regression(reward_counts, params)

is_normalized = params.is_normalized;

each = { 'unit_uuid', 'channel', 'region', 'event-name' };

kept_unit_I = find_units_with_at_least_n_reps( reward_counts, params );
base_mask = kept_unit_I;
targ_mask = find( reward_counts.labels, params.targ_event, base_mask );

[event_I, event_C] = findall( reward_counts.labels, 'event-name', targ_mask );

all_sig = cell( size(event_I) );

for idx = 1:numel(event_I)
  counts = reward_counts.psth;
  labs = reward_counts.labels';
  
  targ_ind = event_I{idx};
  targ_event = event_C{1, idx};
  
  [t_ind, base_t_ind] = get_time_indices( reward_counts, params, targ_event );

  if ( is_normalized )
    base_ind = find( labs, params.base_event, base_mask );
    base_counts = nanmean( counts(base_ind, base_t_ind), 2 );
    
    assert( numel(base_ind) == numel(targ_ind), 'Baseline and target indices mismatch.' );

    targ_counts = nanmean( counts(targ_ind, t_ind), 2 );
    targ_labs = prune( labs(targ_ind) );

    base_I = findall( targ_labs, setdiff(each, 'event-name') );
    base_means = bfw.row_nanmean( base_counts, base_I );
    base_devs = rowop( base_counts, base_I, @(x) nanstd(x, [], 1) );

    for i = 1:numel(base_I)
      targ_counts(base_I{i}) = (targ_counts(base_I{i}) - base_means(i)) / base_devs(i);
    end

    counts = targ_counts;
    labs = prune( labs(targ_ind) );  
    targ_ind = rowmask( labs );
  end

  %%

  mask = intersect( get_base_mask(labs, targ_ind), params.mask_func(labs, counts, targ_event) );

  [labels, each_I] = keepeach( labs', each, mask );
  tables = cell( size(each_I) );
  ps = nan( size(each_I) );

  parfor i = 1:numel(each_I)
    levels = fcat.parse( cellstr(labs, 'reward-level', each_I{i}), 'reward-' );
    subset_counts = counts(each_I{i});

    model = fitglm( levels, subset_counts, 'linear' );
    p = model.Coefficients.pValue(2);

    summary_table = struct();
    summary_table.p = p;

    ps(i) = p;
    tables{i} = struct2table( summary_table );
  end
  
  all_sig{idx} = ps < 0.05;
end

all_sig = or_many( all_sig{:} );

%%

[percs_tbl, counts_tbl] = make_summary_tables( all_sig, labels );

if ( params.do_save )
  save_spec = 'region';
  save_p = get_save_p( params, '3_reward_levels_glm' );
  save_summary_tables( percs_tbl, counts_tbl, save_p, labels, save_spec );
end

end

function reward_level_anova(reward_counts, params)

is_normalized = params.is_normalized;
targ_event = params.targ_event;

labs = reward_counts.labels';
mask = intersect( get_base_mask(labs), params.mask_func(labs, reward_counts.psth, targ_event) );
mask = intersect( mask, find_units_with_at_least_n_reps(reward_counts, params) );

[event_I, event_C] = findall( labs, 'event-name', find(labs, targ_event, mask) );

all_sig_anovas = cell( numel(event_I), 1 );

for i = 1:numel(event_I)
  counts = reward_counts.psth;
  labs = reward_counts.labels';
  
  [t_ind, base_t_ind] = get_time_indices( reward_counts, params, event_C{1, i} );

  if ( is_normalized )
    base_ind = find( labs, params.base_event, mask );    
    base_counts = nanmean( counts(base_ind, base_t_ind), 2 );

    targ_ind = event_I{i};
    targ_counts = nanmean( counts(targ_ind, t_ind), 2 );
    
    assert( numel(base_ind) == numel(targ_ind) );

    counts = targ_counts - base_counts;
    labs = prune( labs(targ_ind) );  
  else
    counts = nanmean( counts(event_I{i}, t_ind), 2 );
    labs = prune( labs(event_I{i}) );
  end

  each = { 'unit_uuid', 'channel', 'region', 'event-name' };
  anova_outs = dsp3.anova1( counts, labs, each, {'reward-level'} );

  anova_ps = cellfun( @(x) x.Prob_F{1}, anova_outs.anova_tables );
  sig_anovas = anova_ps < 0.05;

  all_sig_anovas{i} = sig_anovas;
end

sig_anovas = or_many( all_sig_anovas{:} );

[percs_tbl, counts_tbl] = make_summary_tables( sig_anovas, anova_outs.anova_labels );

if ( params.do_save )
  save_spec = 'region';
  save_p = get_save_p( params, '3_reward_levels_anova' );
  save_summary_tables( percs_tbl, counts_tbl, save_p, anova_outs.anova_labels, save_spec );
end

end

function save_summary_tables(percs_tbl, counts_tbl, save_p, labs, cats)

dsp3.req_writetable( percs_tbl, save_p, labs, cats, 'percentages__' );
dsp3.req_writetable( counts_tbl, save_p, labs, cats, 'counts__' );

end

function [percs_tbl, counts_tbl] = make_summary_tables(is_sig, labels)

[t, rc] = tabular( labels, {'region'}, {'event-name'} );

sig_percs = cellfun( @(x) pnz(is_sig(x)), t ) * 100;
sig_counts = cellfun( @(x) nnz(is_sig(x)), t );

percs_tbl = fcat.table( sig_percs, rc{:} );
counts_tbl = fcat.table( sig_counts, rc{:} );

end

function [t_ind, base_t_ind] = get_time_indices(reward_counts, params, current_event)

if ( nargin > 2 )
  assert( shared_utils.general.is_map_like(params.targ_t) ...
    , 'If specifying a target event, event times must be map-like object.' );
  targ_t = shared_utils.general.get( params.targ_t, current_event );
else
  targ_t = params.targ_t;
end

t_ind = reward_counts.t >= targ_t(1) & reward_counts.t <= targ_t(2);
base_t_ind = reward_counts.t >= params.base_t(1) & reward_counts.t <= params.base_t(2);

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'analyses', 'cs_reward' ...
  , 'reward_level_modulation', dsp3.datedir, params.base_subdir, varargin{:} );

end

function mask = get_base_mask(labels, apply_to)

if ( nargin < 2 )
  apply_to = rowmask( labels );
end

mask = fcat.mask( labels, apply_to ...
  , @findnone, {bfw.nan_unit_uuid(), bfw.nan_reward_level()} ...
  , @find, 'no-error' ...
);

end

function [targ_counts, targ_labs] = get_target_counts(counts, labs, targ_event, mask, t_ind)

assert_ispair( counts, labs );

targ_ind = find( labs, targ_event, mask );
targ_counts = nanmean( counts(targ_ind, t_ind), 2 );
targ_labs = prune( labs(targ_ind) );

end

function I = find_units_with_at_least_n_reps(reward_counts, params)

unit_C = units_with_at_least_n_reps( reward_counts, params );
I = find_units( reward_counts.labels, unit_C );

end

function I = find_units(labels, unit_C)

I = cell( size(unit_C, 2), 1 );

for i = 1:size(unit_C, 2)
  I{i} = find( labels, unit_C(:, i) );  
end

I = vertcat( I{:} );

end

function [unit_C, removed_C, each] = units_with_at_least_n_reps(reward_counts, params)

counts = reward_counts.psth;
labels = reward_counts.labels;
targ_events = params.targ_event;
num_reps = params.min_trials_per_condition;

each = { 'unit_uuid', 'channel', 'region' };

mask = fcat.mask( labels ...
  , @findnone, {bfw.nan_reward_level(), bfw.nan_unit_uuid()} ...
);

reps_of = { 'reward-level' };

[I, each_C] = findall( labels, each, mask );
C = combs( labels, reps_of, mask );

to_keep = true( size(I) );

for i = 1:numel(I)  
  [event_I, targ_event_C] = findall( labels, 'event-name', find(labels, targ_events, I{i}) );
  
  can_keep = true( size(event_I) );
  
  for k = 1:numel(event_I)    
    targ_event = targ_event_C{1, k};
    
    t_ind = get_time_indices( reward_counts, params, targ_event );
    
    for j = 1:size(C, 2)
      ind = find( labels, C(:, j), event_I{k} );
      did_fire = any( counts(ind, t_ind) > 0, 2 );

      if ( nnz(did_fire) < num_reps )
        can_keep(k) = false;
        break;
      end
    end
  end
  
  to_keep(i) = any( can_keep );
end

unit_C = each_C(:, to_keep);
removed_C = each_C(:, ~to_keep);

if ( params.do_save )
  save_p = get_save_p( params );
  shared_utils.io.require_dir( save_p );
  tbl = cell2table( removed_C', 'variablenames', each );
  writetable( tbl, fullfile(save_p, 'removed_units.csv') );
end

end