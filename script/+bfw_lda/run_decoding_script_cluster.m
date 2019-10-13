function run_decoding_script_cluster()

conf = bfw.config.load();
sig_reward_mask_func = make_significant_reward_mask_func( conf );
sig_gaze_mask_func = make_significant_gaze_mask_func( conf );

source_dir = '092619_eyes_face_non_eye_face_nonsocial_object';
base_load_p = fullfile( bfw.dataroot(), 'analyses/spike_lda/reward_gaze_spikes', source_dir );

reward_counts = shared_utils.io.fload( fullfile(base_load_p, 'reward_counts.mat') );
gaze_counts = bfw_lda.load_gaze_counts_all_rois();

kinds = { 'train_gaze_test_reward', 'train_reward_test_gaze' };
invert_roi_pair_order = [ true ];
require_sig_reward = [ true, false ];
require_sig_gaze = [ true, false ];

% kinds = { 'train_gaze_test_gaze' };
% kinds = { 'train_reward_test_reward' };
% invert_roi_pair_order = false;

cmbs = dsp3.numel_combvec( kinds, invert_roi_pair_order, require_sig_reward, require_sig_gaze );

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );

for idx = 1:size(cmbs, 2)
  fprintf( '\n %d of %d', idx, size(cmbs, 2) );
  
  kind = kinds{cmbs(1, idx)};  
  flip_roi_pair_order = invert_roi_pair_order(cmbs(2, idx));
  is_sig_reward = require_sig_reward(cmbs(3, idx));
  is_sig_gaze = require_sig_gaze(cmbs(4, idx));

  switch ( kind )
    case 'train_gaze_test_gaze'
      t_windows = bfw_lda.gaze_time_windows();
    case {'train_gaze_test_reward', 'train_reward_test_gaze', 'train_reward_test_reward'} 
      t_windows = bfw_lda.reward_time_windows();
    otherwise
      error( 'Unrecognized kind "%s".', kind );
  end

  for i = 1:numel(t_windows)
    fprintf( '\n   %d of %d', i, numel(t_windows) );

    t_window = t_windows{i};
    t_window_str = make_t_window_str( t_window );
    base_subdir = fullfile( kind, t_window_str );

    gaze_rois = { 'eyes_nf', 'nonsocial_object', 'face_non_eyes' ...
      , 'face', 'nonsocial_object_eyes_nf_matched' };
    roi_pairs = bfw_lda.roi_pairs();
    
    base_gaze_mask_func = @(labels, mask) findor( labels, gaze_rois, mask );
    base_reward_mask_func = @(labels, mask) mask;

    if ( flip_roi_pair_order )
      base_subdir = sprintf( '%s-flipped-roi-order', base_subdir );
    end
    
    if ( is_sig_reward )
      base_subdir = sprintf( '%s-sig-reward', base_subdir );
      reward_mask_func = sig_reward_mask_func;
    else
      reward_mask_func = base_reward_mask_func;
    end
    
    if ( is_sig_gaze )
      base_subdir = sprintf( '%s-sig-gaze', base_subdir );
      gaze_mask_func = @(labels, mask) sig_gaze_mask_func(labels, base_gaze_mask_func(labels, mask));
    else
      gaze_mask_func = base_gaze_mask_func;
    end

    bfw_lda.run_decoding( gaze_counts, reward_counts ...
      , 'is_over_time', false ...
      , 'base_subdir', base_subdir ...
      , 'gaze_t_window', [0.05, 0.3] ...
      , 'reward_t_window', t_window ...
      , 'require_fixation', true ...
      , 'gaze_mask_func', gaze_mask_func ...
      , 'reward_mask_func', reward_mask_func ...
      , 'roi_pairs', roi_pairs ...
      , 'kinds', kind ...
      , 'flip_roi_order', flip_roi_pair_order ...
      , 'permutation_test', true ...
    );
  end
end

end

function func = make_significant_gaze_mask_func(conf)

unit_info = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses', 'cell_type_classification', '101119', 'cc_anova', 'ANOVAmain3ROIsig_units.mat') );

func = @(labels, mask) bfw_ct.find_significant_unit_info( labels, unit_info, mask );

end

function func = make_significant_reward_mask_func(conf)

subdirs = { '092719', '5_trials_per_condition', 'cs_target_acquire_cs_delay_cs_reward' ...
  , '_iti_baseline_norm_-250_0__0_250__50_600', '3_reward_levels_glm' };

unit_info = bfw_lda.load_sig_reward_level_unit_info( subdirs, conf );
func = @(labels, mask) bfw_ct.find_significant_unit_info( labels, unit_info, mask );

end