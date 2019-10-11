%%

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );

%%  gaze / gaze

datedir = '101019';
kind = 'train_gaze_test_gaze';
flip_roi_pair_order = false;

flip_str = ternary( flip_roi_pair_order, '-flipped-roi-order', '' );

t_windows = ternary( contains(kind, 'reward'), bfw_lda.reward_time_windows(), bfw_lda.gaze_time_windows() );

t_window_strs = eachcell( @(x) sprintf('%s', make_t_window_str(x)), t_windows );
subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );

perf = bfw_lda.load_concatenated_performance( @bfw_lda.load_performance ...
  , load_func_inputs ...
);

%%

to_plot = perf.gg_outs;

bfw_lda.plot_null_performance( to_plot, kind ...
  , 'do_save', true ...
);