reward_subdirs = { ...
    '092719', '5_trials_per_condition' ...
  , 'cs_target_acquire_cs_delay_cs_reward' ...
  , '_iti_baseline_norm_-250_0__0_250__50_600' ...
  , '3_reward_levels_glm' ...
};

% gaze_file = 'ANOVAmainROIsig_units.mat'
gaze_file = 'ANOVAmain3ROIsig_units.mat';
gaze_subdirs = {'101119', 'cc_anova', gaze_file};

reward_info = bfw_lda.load_sig_reward_level_unit_info( reward_subdirs );
gaze_info = shared_utils.io.fload( bfw_ct.base_load_path(gaze_subdirs) );
all_unit_info = shared_utils.io.fload( fullfile(bfw.dataroot(), 'consolidated', 'spike_meta_data.mat') );

%%

reward_counts = bfw_get_cs_reward_response( ...
    'event_names', {'iti'} ...
  , 'look_back', -0.5 ...
  , 'look_ahead', 1.5 ...
  , 'is_firing_rate', false ...
  , 'include_rasters', false ...
);

%%

reward_count_mask = fcat.mask( reward_counts.labels ...
  , @findnone, {bfw.nan_unit_uuid(), bfw.nan_reward_level()} ...
  , @find, 'no-error' ...
);

%%

reward_labels = bfw_ct.cc_unit_meta_data_to_fcat( reward_info );
gaze_labels = bfw_ct.cc_unit_meta_data_to_fcat( gaze_info );
% all_labels = bfw_ct.cc_unit_meta_data_to_fcat( all_unit_info );

all_labels1 = bfw_ct.cc_unit_meta_data_to_fcat( all_unit_info );
all_labels2 = keepeach( reward_counts.labels', {'region', 'unit_uuid', 'session'}, reward_count_mask );
all_labels = all_labels1;

bfw_lda.plot_reward_gaze_significant_cell_info( gaze_labels, reward_labels, all_labels ...
  , 'do_save', true ...
  , 'venn_percent', true ...
  , 'base_subdir', 'all_cells' ...
  , 'prefix', '' ...
  , 'all_mask_func', @(labels, mask) mask ...
);

%%

[session_inds, sessions] = findall( reward_counts.labels, 'session', find(reward_counts.labels, 'bla') );
reward_labs = prune( reward_counts.labels(session_inds{1}) );
gaze_labs = prune( gaze_labels(find(gaze_labels, {sessions{1}, 'bla'})) );

mask_a = session_inds{1};
mask_b = find( gaze_labels, {sessions{1}, 'bla'} );

y = bfw.fcat_union( gaze_labels, reward_counts.labels, 'region', mask_b, mask_a );


