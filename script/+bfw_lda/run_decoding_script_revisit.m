% source_dir = '09062019_eyes_v_non_eyes_face';
% source_dir = 'revisit_09032019';
% source_dir = '091119_nsobj_eyes_matched';
% source_dir = '091219_ns_obj_non_collapsed_eyes_matched';
source_dir = '092619_eyes_face_non_eye_face_nonsocial_object';

base_load_p = fullfile( bfw.dataroot() ...
  , 'analyses/spike_lda/reward_gaze_spikes' ...
  , source_dir ...
);

%%

reward_counts = shared_utils.io.fload( fullfile(base_load_p, 'reward_counts.mat') );
% gaze_counts = shared_utils.io.fload( fullfile(base_load_p, 'gaze_counts.mat') );

gaze_counts = bfw_lda.load_gaze_counts_all_rois();

%%

% kinds = { 'train_gaze_test_gaze', 'train_gaze_test_reward', 'train_reward_test_gaze' };
% invert_roi_pair_order = [ true, false ];

% kinds = { 'train_gaze_test_gaze' };

kinds = { 'train_reward_test_reward' };
invert_roi_pair_order = false;

cmbs = dsp3.numel_combvec( kinds, invert_roi_pair_order );

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );

for idx = 1:size(cmbs, 2)
  shared_utils.general.progress( idx, size(cmbs, 2) );
  
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
    shared_utils.general.progress( i, numel(t_windows) );

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
  
%%  load/plot train gaze/reward, reward/gaze, or reward/reward

% datedir = '100119';
datedir = '100819';

% kinds = { 'train_gaze_test_reward', 'train_reward_test_gaze' };
kinds = { 'train_reward_test_reward' };
flip_roi_pair_order = false;

for i = 1:numel(kinds)
  flip_str = ternary( flip_roi_pair_order, '-flipped-roi-order', '' );  
  kind = kinds{i};
  
  t_window_strs = cellfun( @(x) sprintf('%s%s', make_t_window_str(x), flip_str) ...
    , bfw_lda.reward_time_windows(), 'un', 0 );
  subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

  events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };

  load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );

  perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance ...
    , load_func_inputs ...
    , @(labels, i) find(labels, events{i}) ...
  );

  bfw_lda.plot_decoding( perf ...
    , 'base_subdir', sprintf('%s%s', kind, flip_str) ...
    , 'do_save', true ...
  );
end

%%  load/plot train gaze test gaze, train reward test reward

% datedir = '100119';
datedir = '100819';
kind = 'train_gaze_test_gaze';
flip_roi_pair_order = true;

flip_str = ternary( flip_roi_pair_order, '-flipped-roi-order', '' );

t_window_strs = cellfun( @(x) sprintf('%s%s', make_t_window_str(x), flip_str) ...
  , bfw_lda.gaze_time_windows(), 'un', 0 );
subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );

perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance ...
  , load_func_inputs ...
);

bfw_lda.plot_decoding( perf ...
  , 'base_subdir', sprintf('%s%s', kind, flip_str) ...
  , 'do_save', true ...
);

%%

bfw_lda.plot_decoding( perf ...
  , 'base_subdir', 'left-obj' ...
  , 'do_save', true ...
);

%%  load timecourse

datedir = '091019';
subdirs = {datedir, 'train_gaze_test_gaze-timecourse-enef/train-on-50-300'};
rest_subdirs = subdirs;
rest_subdirs{2} = strrep( rest_subdirs{2}, '-enef', '' );

perf = bfw_lda.load_performance_combined_eyes_non_eyes_face( subdirs, rest_subdirs );


%%

bfw_lda.plot_decoding_timecourse( perf ...
  , 'do_save', true ...
);

%%
% 
% %%  load train gaze test reward
% 
% datedir = '090919';
% kind = 'train_gaze_test_reward-enef';
% t_windows = { [-0.25, 0], [0, 0.25], [0.05, 0.6] };
% 
% t_window_strs = cellfun( make_t_window_str, t_windows, 'un', 0 );
% subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );
% rest_subdirs = cellfun( @(x) {x{1}, strrep(x{2}, '-enef', ''), x{3}}, subdirs, 'un', 0 );
% 
% events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };
% 
% load_func_inputs = cellfun( @(x, y) {x, y}, subdirs, rest_subdirs, 'un', 0 );
% 
% perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance_combined_eyes_non_eyes_face ...
%   , load_func_inputs ...
%   , @(labels, i) find(labels, events{i}) ...
% );
% 
% %%  load train gaze test gaze
% 
% kind = 'train_gaze_test_gaze-left-obj';
% t_window = [0.05, 0.3];
% datedir = '091219';
% subdirs = { datedir, kind, make_t_window_str(t_window) };
% rest_subdirs = { subdirs{1}, strrep(kind, '-enef', ''), subdirs{3} };
% 
% % perf = bfw_lda.load_performance_combined_eyes_non_eyes_face( subdirs, rest_subdirs );
% perf = bfw_lda.load_performance( subdirs );
% 
% %%  load train reward test gaze
% 
% datedir = '090619';
% kind = 'train_reward_test_gaze-enef';
% t_windows = { [-0.25, 0], [0, 0.25], [0.05, 0.6] };
% 
% t_window_strs = cellfun( make_t_window_str, t_windows, 'un', 0 );
% subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );
% rest_subdirs = cellfun( @(x) {x{1}, strrep(x{2}, '-enef', ''), x{3}}, subdirs, 'un', 0 );
% 
% events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };
% 
% load_func_inputs = cellfun( @(x, y) {x, y}, subdirs, rest_subdirs, 'un', 0 );
% 
% perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance_combined_eyes_non_eyes_face ...
%   , load_func_inputs ...
%   , @(labels, i) find(labels, events{i}) ...
% );
% 
% %%  load train reward test reward
% 
% datedir = '090619';
% kind = 'train_reward_test_reward';
% t_windows = { [-0.25, 0], [0, 0.25], [0.05, 0.6] };
% events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };
% 
% t_window_strs = cellfun( make_t_window_str, t_windows, 'un', 0 );
% subdirs = cellfun( @(x) {{datedir, kind, x}}, t_window_strs, 'un', 0 );
% 
% perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance ...
%   , subdirs ...
%   , @(labels, i) find(labels, events{i}) ...
% );