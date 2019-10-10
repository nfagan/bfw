base_load_p = fullfile( bfw.dataroot(), 'analyses/spike_lda/reward_gaze_spikes' );

load_func = @(subdir, kind) shared_utils.io.fload( fullfile(base_load_p, subdir, kind) );

enef_gaze = load_func( '09062019_eyes_v_non_eyes_face', 'gaze_counts.mat' );
rest_gaze = load_func( 'revisit_09032019', 'gaze_counts.mat' );
reward_counts = load_func( 'revisit_09032019', 'reward_counts.mat' );

%%

gaze_counts = bfw_lda.combine_non_eye_face_with_rest_gaze_counts( enef_gaze, rest_gaze );
bfw.unify_single_region_labels( gaze_counts.labels );

%%  Unit meta-data for cells that significantly discriminate social vs. nonsocial

sig_gaze_info = bfw_ct.load_nested_anova_significant_cell_ids( ...
  {'092419', 'main_effect_significant', '0_250'} ...
);

sig_gaze_labels = bfw_ct.significant_unit_info_to_fcat( sig_gaze_info );
[sig_counts, sig_count_labels] = bfw_lda.count_units_per_region( sig_gaze_labels );
[tot_counts, tot_count_labels] = bfw_lda.count_units_per_region( gaze_counts.labels );

%%  train gaze test reward

is_significant_units = false;

t_windows = { [-0.25, 0], [0, 0.25], [0.05, 0.6] };
kind = 'train_gaze_test_reward-matched';

%%

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );

if ( is_significant_units )
  find_unit_func = @bfw_ct.find_significant_unit_info;
  sig_str = 'significant-gaze';
  additional_funcs = {};
else
  find_unit_func = @bfw_ct.findnot_significant_unit_info;
  sig_str = 'nonsignificant-gaze';
  additional_funcs = {
    @(labels, ~, mask) bfw_lda.find_random_subset_per_region(labels, mask, sig_counts, sig_count_labels), {} ...
  };
end

kind = sprintf( '%s-%s', kind, sig_str );

gaze_mask_func = @(labels, mask) fcat.mask(labels, mask ...
  , find_unit_func, sig_gaze_info ...
  , @findnone, 'face' ...
  , additional_funcs{:} ...
);

reward_mask_func = @(labels, mask) fcat.mask(labels, mask ...
  , find_unit_func, sig_gaze_info ...
  , additional_funcs{:} ...
);

%%  train gaze test reward

for i = 1:numel(t_windows)
  shared_utils.general.progress( i, numel(t_windows) );
  
  t_window = t_windows{i};
  t_window_str = make_t_window_str( t_window );
  base_subdir = fullfile( kind, t_window_str );

  bfw_lda.run_decoding( gaze_counts, reward_counts ...
    , 'is_over_time', false ...
    , 'base_subdir', base_subdir ...
    , 'gaze_t_window', [0.05, 0.3] ...
    , 'reward_t_window', t_window ...
    , 'require_fixation', true ...
    , 'gaze_mask_func', gaze_mask_func ...
    , 'reward_mask_func', reward_mask_func ...
  );
end

%%

datedir = '092619';

t_window_strs = cellfun( make_t_window_str, t_windows, 'un', 0 );
subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };

load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );

perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance ...
  , load_func_inputs ...
  , @(labels, i) find(labels, events{i}) ...
);

%%

bfw_lda.plot_decoding( perf ...
  , 'base_subdir', kind ...
  , 'do_save', true ...
);


