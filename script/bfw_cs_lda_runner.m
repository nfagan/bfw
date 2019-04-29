reward_response = bfw_get_cs_reward_response( ...
  'event_names', {'cs_reward', 'cs_presentation'} ...
);

%%

sensitivity_outs = bfw_determine_reward_sensitivity_runner( reward_response ...
  , 'make_levels_binary', false ...
  , 'model_type', 'glm' ...
);

sens_perf = sensitivity_outs.performance;
sens_p = sensitivity_outs.significance;
sens_labels = sensitivity_outs.labels';

%%

% lda_subdirs = { '041519', '041719', 'outside1_post_event_042219' };
lda_subdirs = { 'outside1_pre_event_042219', 'everywhere_pre_event_042219' };

lda_files = cellfun( @(x) fullfile(x, 'lda_out.mat'), lda_subdirs, 'un', 0 );
lda_outs = bfw_load_mult_cs_lda_data( lda_files );

%%

bfw_reward_sensitivity_gaze_relationship( sens_perf, sens_p, sens_labels', lda_outs ...
  , 'do_save', true ...
  , 'base_subdir', 'pre_gaze_svm_sensitivity' ...
);

%%

bfw_run_plot_cs_reward_response( reward_response, sensitivity_outs );

%%

sig_mask = fcat.mask( sensitivity_outs.labels, find(sens_p < 0.05) ...
  , @findnone, 'unit_uuid__NaN' ...
);

sig_units = combs( sensitivity_outs.labels, 'unit_uuid', sig_mask );

sig_subdir = 'significant_reward_sensitivity';
nonsig_subdir = 'all_sensitivity';
do_save = true;

% Only significantly sensitivity modulated
bfw_plot_gaze_lda_model_performance( lda_outs.performance, lda_outs.labels' ...
  , 'do_save', do_save ...
  , 'mask_func', @(labels, mask) find(labels, sig_units, mask) ...
  , 'base_subdir', sig_subdir ...
);

bfw_plot_gaze_lda_model_performance( lda_outs.performance, lda_outs.labels' ...
  , 'do_save', do_save ...
  , 'base_subdir', nonsig_subdir ...
);

