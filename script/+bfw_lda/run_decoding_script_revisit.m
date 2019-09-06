base_load_p = fullfile( bfw.dataroot() ...
  , 'analyses/spike_lda/reward_gaze_spikes' ...
  , 'revisit_09032019' ...
);

%%

reward_counts = shared_utils.io.fload( fullfile(base_load_p, 'reward_counts.mat') );
gaze_counts = shared_utils.io.fload( fullfile(base_load_p, 'gaze_counts.mat') );

%%

% t_windows = { [-0.25, 0], [0, 0.25], [0.05, 0.6] };
t_windows = { [0.05, 0.3] };
kind = 'train_gaze_test_gaze';

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );

for i = 1:numel(t_windows)
  shared_utils.general.progress( 1, numel(t_windows) );
  
  t_window = t_windows{i};
  t_window_str = make_t_window_str( t_window );
  base_subdir = fullfile( kind, t_window_str );

  bfw_lda.run_decoding( gaze_counts, reward_counts ...
    , 'base_subdir', base_subdir ...
  );
end

%%
t_window = [0.05, 0.3];
datedir = '090619';
subdirs = { datedir, kind, make_t_window_str(t_window) };
perf = bfw_lda.load_performance( subdirs );

%%

bfw_lda.plot_decoding( perf ...
  , 'base_subdir', subdirs{3} ...
  , 'do_save', false ...
  , 'mask_func', @(labels) findnot(labels, 'eyes_nf/face') ...
);

%%