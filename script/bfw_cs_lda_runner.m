reward_response = bfw_get_cs_reward_response( ...
  'event_names', {'cs_reward', 'cs_presentation'} ...
);

lda_outs = bfw_load_mult_cs_lda_data( {'041519/lda_out.mat', '041719/lda_out.mat'} );
sensitivity_outs = bfw_determine_reward_sensitivity( reward_response );

sens_perf = sensitivity_outs.performance;
sens_p = sensitivity_outs.significance;

%%

bfw_reward_sensitivity_gaze_relationship( sens_perf, sens_p, stats_labels', lda_outs ...
  , 'do_save', true ...
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