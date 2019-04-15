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
  , 'make_levels_binary', true ...
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

bfw_run_roi_pair_spike_lda()

%%  Load lda

lda_out = shared_utils.io.fload( fullfile(bfw.dataroot, 'analyses/spike_lda/041219/lda_out.mat') );

if ( isfield(lda_out, 'percent_correct') )
  lda_out.performance = lda_out.percent_correct;
  lda_out = rmfield( lda_out, 'percent_correct' );
end

[diffs, labels, I] = dsp3.summary_binary_op( lda_out.performance, lda_out.labels' ...
  , {'unit_uuid', 'session', 'roi'}, 'non-shuffled', 'shuffled', @minus, @identity );

any_missing = cellfun( @(x) any(lda_out.performance(x, 2)), I );
diffs(any_missing, :) = nan;

%%

sens_perf = sensitivity_outs.model_stats(:, strcmp(sensitivity_outs.model_stats_key, 'pValue'));
sens_labels = sensitivity_outs.labels';

lda_perf = lda_out.performance;
lda_labels = lda_out.labels';

sens_perf = indexpair( sens_perf, sens_labels, findnone(sens_labels, 'unit_uuid__NaN') );

bfw_correlate_cs_reward_sensitivity_to_gaze_lda( sens_perf, sens_labels', lda_perf, lda_labels' );

