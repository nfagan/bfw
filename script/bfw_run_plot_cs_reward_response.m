reward_response = bfw_get_cs_reward_response( ...
  'event_names', {'cs_reward', 'cs_presentation'} ...
);

%%  Determine per-unit reward sensitivity

base_mask = find( reward_response.labels, 'no-error' );
sens_each = { 'unit_uuid', 'event-name', 'session' };

each_func = @(labels, mask) findall(labels, sens_each, intersect(mask, base_mask));

sensitivity_outs = bfw_determine_cs_reward_sensitivity_glm( reward_response ...
  , 'each_func', each_func ...
  , 'time_window', [0, 0.4] ...
  , 'make_levels_binary', false ...
);

%%  Plot prop. of significantly modulated units

bfw_plot_cs_reward_sensitivity( sensitivity_outs );

%%  Plot psth of significantly modulated units

model_stats = sensitivity_outs.model_stats;

ps = model_stats(:, strcmp(sensitivity_outs.model_stats_key, 'pValue'));

is_sig = ps < 0.05;
sig_units = combs( sensitivity_outs.labels, 'unit_uuid', find(is_sig) );

bfw_plot_cs_reward_response( reward_response ...
  , 'base_subdir', 'significant_units_each_level' ...
  , 'base_mask', findor(reward_response.labels, sig_units) ...
  , 'do_save', true ...
);

%%  Run lda

% bfw_run_roi_pair_spike_lda();

%%  Load lda

% lda_file = '041219/lda_out.mat';
lda_file = '041519/lda_out.mat';

lda_out = shared_utils.io.fload( fullfile(bfw.dataroot, 'analyses/spike_lda', lda_file) );

shuff_ind = find( lda_out.labels, 'shuffled' );

if ( isfield(lda_out, 'percent_correct') ) 
  lda_out.performance = lda_out.percent_correct;
  lda_out.performance(:, 3) = 0;
  lda_out = rmfield( lda_out, 'percent_correct' );
else
  lda_out.performance(shuff_ind, 3) = 0;
end

[diffs, diff_labels, I] = dsp3.summary_binary_op( lda_out.performance, lda_out.labels' ...
  , {'unit_uuid', 'session', 'roi'}, 'non-shuffled', 'shuffled', @minus, @identity );

ns = unique( cellfun(@numel, I) );
assert( numel(ns) == 1 && ns == 2 );

any_missing = cellfun( @(x) any(lda_out.performance(x, 2)), I );
diffs(any_missing, :) = nan;

%%  Get distributions of reward sensitivity + lda performance

base_subdir = 'signed_lda_diff_from_shuffled';

use_lda_diff = true;

model_stats = sensitivity_outs.model_stats;
stats_key = sensitivity_outs.model_stats_key;

sens_perf = model_stats(:, strcmp(stats_key, 'Estimate'));
sens_p = model_stats(:, strcmp(stats_key, 'pValue'));
sens_labels = sensitivity_outs.labels';

if ( use_lda_diff )
  lda_perf = diffs(:, 1) * 100;
  lda_p = diffs(:, 2);
  lda_labels = diff_labels';
else
  lda_perf = lda_out.performance(:, 1) * 100;
  lda_p = lda_out.performance(:, 3);
  lda_labels = lda_out.labels';
end

bfw.unify_single_region_labels( lda_labels );

bfw_run_cs_lda_correlation( sens_perf, sens_p, sens_labels' ...
  , lda_perf, lda_p, lda_labels' ...
  , 'significant_reward', true ...
  , 'absolute_reward', true ...
  , 'do_save', true ...
  , 'base_subdir', base_subdir ...
);

