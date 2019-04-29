function bfw_plot_gaze_lda_model_performance_combinations(sensitivity_outs)

sens_p = sensitivity_outs.significance;
sens_labels = sensitivity_outs.labels';

sig_mask = fcat.mask( sens_labels, find(sens_p < 0.05) ...
  , @findnone, 'unit_uuid__NaN' ...
);

sig_units = combs( sens_labels, 'unit_uuid', sig_mask );

sig_subdir = 'significant_reward_sensitivity';
nonsig_subdir = 'all_sensitivity';
do_save = true;

lda_subdirs = { ...
    {'outside1_pre_event_042219', 'everywhere_pre_event_042219', 'nonsocial_object_pre_event_042319'} ...
  , {'outside1_post_event_042319', 'everywhere_post_event_042319', 'nonsocial_object_post_event_042319'} ...
};

for i = 1:numel(lda_subdirs)
  lda_subdir = lda_subdirs{i};
  lda_files = cellfun( @(x) fullfile(x, 'lda_out.mat'), lda_subdir, 'un', 0 );
  
  lda_outs = bfw_load_mult_cs_lda_data( lda_files );
  
  is_pre = any( cellfun(@(x) ~isempty(strfind(x, 'pre')), lda_files) );
  pre_subdir = ternary( is_pre, 'pre_gaze', 'post_gaze' );
  
  use_sig_subdir = sprintf( '%s_%s', pre_subdir, sig_subdir );
  use_nonsig_subdir = sprintf( '%s_%s', pre_subdir, nonsig_subdir );

  % Only significantly sensitivity modulated
  bfw_plot_gaze_lda_model_performance( lda_outs.performance, lda_outs.labels' ...
    , 'do_save', do_save ...
    , 'mask_func', @(labels, mask) find(labels, sig_units, mask) ...
    , 'base_subdir', use_sig_subdir ...
  );

  bfw_plot_gaze_lda_model_performance( lda_outs.performance, lda_outs.labels' ...
    , 'do_save', do_save ...
    , 'base_subdir', use_nonsig_subdir ...
  );
end

end