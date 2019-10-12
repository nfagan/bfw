function run_decoding_script_cluster()

source_dir = '092619_eyes_face_non_eye_face_nonsocial_object';
base_load_p = fullfile( bfw.dataroot(), 'analyses/spike_lda/reward_gaze_spikes', source_dir );

reward_counts = shared_utils.io.fload( fullfile(base_load_p, 'reward_counts.mat') );
gaze_counts = bfw_lda.load_gaze_counts_all_rois();

kinds = { 'train_gaze_test_reward', 'train_reward_test_gaze' };
invert_roi_pair_order = [ true, false ];

% kinds = { 'train_gaze_test_gaze' };
% kinds = { 'train_reward_test_reward' };
% invert_roi_pair_order = false;

cmbs = dsp3.numel_combvec( kinds, invert_roi_pair_order );

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );

for idx = 1:size(cmbs, 2)
  fprintf( '\n %d of %d', idx, size(cmbs, 2) );
  
  kind = kinds{cmbs(1, idx)};  
  flip_roi_pair_order = invert_roi_pair_order(cmbs(2, idx));

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

    if ( flip_roi_pair_order )
      base_subdir = sprintf( '%s-flipped-roi-order', base_subdir );
    end

    bfw_lda.run_decoding( gaze_counts, reward_counts ...
      , 'is_over_time', false ...
      , 'base_subdir', base_subdir ...
      , 'gaze_t_window', [0.05, 0.3] ...
      , 'reward_t_window', t_window ...
      , 'require_fixation', true ...
      , 'gaze_mask_func', @(labels, mask) findor(labels, gaze_rois, mask) ...
      , 'roi_pairs', roi_pairs ...
      , 'kinds', kind ...
      , 'flip_roi_order', flip_roi_pair_order ...
      , 'permutation_test', true ...
    );
  end
end