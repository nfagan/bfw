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

datedir = '101419';
kinds = {'train_reward_test_gaze', 'train_gaze_test_reward'};
% kinds = {'train_gaze_test_reward'};

flip_roi_pair_orders = [ false ];
is_sig_gazes = [ true, false ];
is_sig_rewards = [ true, false ];

do_save = true;

perf_combs = dsp3.numel_combvec( flip_roi_pair_orders, is_sig_gazes, is_sig_rewards, kinds );

for idx = 1:size(perf_combs, 2)
  shared_utils.general.progress( idx, size(perf_combs, 2) );
  
  perf_comb = perf_combs(:, idx);
  flip_roi_pair_order = flip_roi_pair_orders(perf_comb(1));
  is_sig_gaze = is_sig_gazes(perf_comb(2));
  is_sig_reward = is_sig_rewards(perf_comb(3));
  kind = kinds{perf_comb(4)};

  flip_str = ternary( flip_roi_pair_order, '-flipped-roi-order', '' );
  sig_str = '';
  
  if ( is_sig_reward )
    sig_str = sprintf( '%s-sig-reward', sig_str );
  end
  if ( is_sig_gaze )
    sig_str = sprintf( '%s-sig-gaze', sig_str );
  end

  t_window_strs = cellfun( @(x) sprintf('%s%s%s', make_t_window_str(x), flip_str, sig_str) ...
    , bfw_lda.reward_time_windows(), 'un', 0 );
  subdirs = cellfun( @(x) {datedir, kind, x}, t_window_strs, 'un', 0 );

  events = { 'cs_target_acquire', 'cs_delay', 'cs_reward' };

  load_func_inputs = cellfun( @(x) {x}, subdirs, 'un', 0 );
  load_func = @(varargin) bfw_lda.load_performance( varargin{:}, conf );

  try
    perf = bfw_lda.load_concatenated_performance( load_func ...
      , load_func_inputs ...
      , @(labels, i) find(labels, events{i}) ...
    );
  catch err
    warning( err.message );
    continue;
  end

  to_plot = perf.(bfw_lda.performance_field_from_kind(kind));

  %

  base_subdir = ternary( flip_roi_pair_order, 'flipped-order', 'non-flipped-order' );
  base_subdir = sprintf( '%s%s', base_subdir, sig_str );

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

end