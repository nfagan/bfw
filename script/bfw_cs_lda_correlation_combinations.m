function bfw_cs_lda_correlation_combinations(reward_response)

model_types = { 'glm', 'lda' };
lda_subdirs = { ...
    {'outside1_pre_event_042219', 'everywhere_pre_event_042219'} ...
  , {'outside1_post_event_042319', 'everywhere_pre_event_042319'} ...
  , {'nonsocial_object_pre_event_042319'} ...
  , {'nonsocial_object_post_event_042319'} ...
};

C = dsp3.numel_combvec( model_types, lda_subdirs );

cached_sensitivity = containers.Map();

for i = 1:size(C, 2)

comb = C(:, i);
model_type = model_types{comb(1)};
lda_subdir = lda_subdirs{comb(2)};

make_levels_binary = strcmp( model_type, 'glm' );

lda_files = cellfun( @(x) fullfile(x, 'lda_out.mat'), lda_subdir, 'un', 0 );
lda_outs = bfw_load_mult_cs_lda_data( lda_files );

if ( ~isKey(cached_sensitivity, model_type) )
  sensitivity_outs = bfw_determine_reward_sensitivity_runner( reward_response ...
    , 'make_levels_binary', make_levels_binary ...
    , 'model_type', model_type ...
  );
  cached_sensitivity(model_type) = sensitivity_outs;
end

sensitivity_outs = cached_sensitivity(model_type);

sens_perf = sensitivity_outs.performance;
sens_p = sensitivity_outs.significance;
sens_labels = sensitivity_outs.labels';

bfw_reward_sensitivity_gaze_relationship( sens_perf, sens_p, sens_labels', lda_outs ...
  , 'do_save', true ...
  , 'base_subdir', 'pre_gaze_svm_sensitivity' ...
);

end