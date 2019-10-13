%%

make_t_window_str = @(win) sprintf( 'train-on-%d-%d', win(1)*1e3, win(2)*1e3 );
conf = bfw.config.load();
conf.PATHS.data_root = '/Users/Nick/Desktop/bfw';

%%  gaze / gaze, reward/reward

datedir = '101019';
kind = 'train_gaze_test_gaze';
flip_roi_pair_order = false;

flip_str = ternary( flip_roi_pair_order, '-flipped-roi-order', '' );

t_windows = ternary( contains(kind, 'reward'), bfw_lda.reward_time_windows(), bfw_lda.gaze_time_windows() );

t_window_strs = eachcell( @(x) sprintf('%s', make_t_window_str(x)), t_windows );
subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );
load_func = @(varargin) bfw_lda.load_performance( varargin{:}, conf );

perf = bfw_lda.load_concatenated_performance( load_func, load_func_inputs );

%%  gaze/reward, reward/gaze

datedir = '101219';
kind = 'train_gaze_test_reward';
flip_roi_pair_order = true;

flip_str = ternary( flip_roi_pair_order, '-flipped-roi-order', '' );

t_window_strs = cellfun( @(x) sprintf('%s%s', make_t_window_str(x), flip_str) ...
  , bfw_lda.reward_time_windows(), 'un', 0 );
subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };

load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );
load_func = @(varargin) bfw_lda.load_performance( varargin{:}, conf );

perf = bfw_lda.load_concatenated_performance( load_func ...
  , load_func_inputs ...
  , @(labels, i) find(labels, events{i}) ...
);

to_plot = perf.(bfw_lda.performance_field_from_kind(kind));

%%

do_save = true;
base_subdir = ternary( flip_roi_pair_order, 'flipped-order', 'non-flipped-order' );

sep_fig_combs = [ true, false ];
comb_inds = dsp3.numel_combvec( sep_fig_combs );

for i = 1:size(comb_inds, 2)
  separate_figures_for_event_name = sep_fig_combs(comb_inds(1, i));

  bfw_lda.plot_null_performance( to_plot, kind ...
    , 'do_save', do_save ...
    , 'separate_figures_for_event_name', separate_figures_for_event_name ...
    , 'base_subdir', base_subdir ...
    , 'config', conf ...
  );
end