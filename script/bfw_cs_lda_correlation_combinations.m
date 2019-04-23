function bfw_cs_lda_correlation_combinations(reward_response)

sensitivity_model_types = { 'glm', 'lda' };
lda_subdirs = { ...
    {'outside1_pre_event_042219', 'everywhere_pre_event_042219'} ...
  , {'outside1_post_event_042319', 'everywhere_post_event_042319'} ...
  , {'nonsocial_object_pre_event_042319'} ...
  , {'nonsocial_object_post_event_042319'} ...
};

C = dsp3.numel_combvec( sensitivity_model_types, lda_subdirs );

cached_sensitivity = containers.Map();
cached_gaze = containers.Map();

for i = 1:size(C, 2)
  shared_utils.general.progress( i, size(C, 2) );

  comb = C(:, i);
  sensitivity_model_type = sensitivity_model_types{comb(1)};
  lda_subdir = lda_subdirs{comb(2)};

  make_levels_binary = strcmp( sensitivity_model_type, 'glm' );
  is_pre = cellfun( @(x) ~isempty(strfind(x, 'pre')), lda_subdir );
  assert( xor(all(is_pre), ~any(is_pre)) );

  lda_file_str = strjoin( lda_subdir, '' );

  if ( ~isKey(cached_gaze, lda_file_str) )
    lda_files = cellfun( @(x) fullfile(x, 'lda_out.mat'), lda_subdir, 'un', 0 );
    cached_gaze(lda_file_str) = bfw_load_mult_cs_lda_data( lda_files );
  end

  lda_outs = cached_gaze(lda_file_str);

  if ( ~isKey(cached_sensitivity, sensitivity_model_type) )
    cached_sensitivity(sensitivity_model_type) = bfw_determine_reward_sensitivity_runner( reward_response ...
      , 'make_levels_binary', make_levels_binary ...
      , 'model_type', sensitivity_model_type ...
    );
  end

  sensitivity_outs = cached_sensitivity(sensitivity_model_type);

  sens_perf = sensitivity_outs.performance;
  sens_p = sensitivity_outs.significance;
  sens_labels = sensitivity_outs.labels';

  pre_subdir = ternary( is_pre, 'pre_gaze', 'post_gaze' );
  base_subdir = sprintf( '%s_%s_sensitivity', pre_subdir, sensitivity_model_type );

  bfw_reward_sensitivity_gaze_relationship( sens_perf, sens_p, sens_labels', lda_outs ...
    , 'do_save', true ...
    , 'base_subdir', base_subdir ...
  );
end