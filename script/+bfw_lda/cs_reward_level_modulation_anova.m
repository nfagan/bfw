function cs_reward_level_modulation_anova(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.reward_counts = [];
defaults.reward_t = [0.05, 0.4];
defaults.base_t = [0, 0.15];
defaults.base_event = 'fixation';
defaults.lda_holdout = 0.25;
defaults.lda_iters = 1e2;
defaults.lda_rng_seed = [];

params = bfw.parsestruct( defaults, varargin );

reward_counts = params.reward_counts;

if ( isempty(reward_counts) )
  reward_counts = bfw_get_cs_reward_response( ...
      'event_names', {'cs_presentation', params.base_event} ...
    , 'look_back', -0.2 ...
    , 'look_ahead', 1 ...
    , 'is_firing_rate', false ...
    , 'include_rasters', false ...
  );
end

compare_small_large( reward_counts, params );
decode_small_large( reward_counts, params );
reward_level_regression( reward_counts, params );
compare_baseline( reward_counts, params );
reward_level_anova( reward_counts, params );

end

function decode_small_large(reward_counts, params)

counts = reward_counts.psth;
labs = reward_counts.labels';

[t_ind, ~] = get_time_indices( reward_counts, params );

mask = get_base_mask( labs );
[targ_counts, targ_labs] = get_target_counts( counts, labs, mask, t_ind );

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

counts = reward_counts.psth;
labs = reward_counts.labels';

[t_ind, ~] = get_time_indices( reward_counts, params );

mask = get_base_mask( labs );
[targ_counts, targ_labs] = get_target_counts( counts, labs, mask, t_ind );

each = { 'unit_uuid', 'channel', 'region' };

stat_outs = dsp3.ranksum( targ_counts, targ_labs, each, 'reward-1', 'reward-3' );

ps = cellfun( @(x) x.p, stat_outs.rs_tables );
is_sig = ps < 0.05;

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

targ_ind = find( labs, 'cs_presentation' );
targ_counts = nanmean( counts(targ_ind, t_ind), 2 );

mask = get_base_mask( labs );

counts = zeros( rows(counts), 1 );
counts(base_ind) = base_counts;
counts(targ_ind) = targ_counts;

each = { 'unit_uuid', 'channel', 'region' };

stat_outs = dsp3.ranksum( counts, labs, each, 'cs_presentation', params.base_event ...
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

is_normalized = true;

[t_ind, base_t_ind] = get_time_indices( reward_counts, params );

counts = reward_counts.psth;
labs = reward_counts.labels';

each = { 'unit_uuid', 'channel', 'region', 'event-name' };

if ( is_normalized )
  base_ind = find( labs, params.base_event );
  base_counts = nanmean( counts(base_ind, base_t_ind), 2 );
  
  targ_ind = find( labs, 'cs_presentation' );
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
end

%%

mask = get_base_mask( labs );

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

%%

[percs_tbl, counts_tbl] = make_summary_tables( ps < 0.05, labels );

if ( params.do_save )
  save_spec = 'region';
  save_p = get_save_p( params, '3_reward_levels_glm' );
  save_summary_tables( percs_tbl, counts_tbl, save_p, labels, save_spec );
end

end

function reward_level_anova(reward_counts, params)

is_normalized = false;

[t_ind, base_t_ind] = get_time_indices( reward_counts, params );

counts = reward_counts.psth;
labs = reward_counts.labels';

if ( is_normalized )
  base_ind = find( labs, params.base_event );
  base_counts = nanmean( counts(base_ind, base_t_ind), 2 );
  
  targ_ind = find( labs, 'cs_presentation' );
  targ_counts = nanmean( counts(targ_ind, t_ind), 2 );
  
  counts = targ_counts - base_counts;
  labs = prune( labs(targ_ind) );  
else
  counts = nanmean( counts(:, t_ind), 2 );
end

mask = get_base_mask( labs );

each = { 'unit_uuid', 'channel', 'region', 'event-name' };

anova_outs = dsp3.anova1( counts, labs, each, {'reward-level'} ...
  , 'mask', mask ...
);
%%

anova_ps = cellfun( @(x) x.Prob_F{1}, anova_outs.anova_tables );
sig_anovas = anova_ps < 0.05;

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

function [t_ind, base_t_ind] = get_time_indices(reward_counts, params)

t_ind = reward_counts.t >= params.reward_t(1) & reward_counts.t <= params.reward_t(2);
base_t_ind = reward_counts.t >= params.base_t(1) & reward_counts.t <= params.base_t(2);

end

function save_p = get_save_p(params, varargin)

save_p = fullfile( bfw.dataroot(params.config), 'analyses', 'cs_reward' ...
  , 'reward_level_modulation', dsp3.datedir, params.base_subdir, varargin{:} );

end

function mask = get_base_mask(labels)

mask = fcat.mask( labels ...
  , @findnone, {bfw.nan_unit_uuid(), bfw.nan_reward_level()} ...
  , @find, 'no-error' ...
);

end

function [targ_counts, targ_labs] = get_target_counts(counts, labs, mask, t_ind)

assert_ispair( counts, labs );

targ_ind = find( labs, 'cs_presentation', mask );
targ_counts = nanmean( counts(targ_ind, t_ind), 2 );
targ_labs = prune( labs(targ_ind) );

end