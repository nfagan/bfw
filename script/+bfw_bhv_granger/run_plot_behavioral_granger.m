repadd granger;

look_outputs = bfw_make_looking_vector( ...
  'rois', 'face' ...
  , 'files_containing', {'2019_'} ...
);

%%

bfw_run_behavioral_granger( ...
  'look_outputs', look_outputs ...
  , 'prefix', '500_window_1000_step_10_sessions_' ...
  , 'do_save', true ...
);

%%

% date_dir = '020720';
% fname = '2-days_granger_1.mat';
% fname = '10e3_window_granger_1.mat';

% date_dir = '021720';
date_dir = '030320';
% fname = '500_window_10_sessions_granger_1.mat';
fname = 'permutation_testgranger_1.mat';

load_p = bfw_bhv_granger.granger_save_p( {date_dir} );
file_p = fullfile( load_p, fname );

granger_outs = shared_utils.io.fload( file_p );

%%

granger_outs = shared_utils.io.fload( '/Users/Nick/Desktop/030520/permutation_testgranger_1.mat' );

%%

mask_func = @(l, m) fcat.mask( l, m ...
  ...
);

bfw_bhv_granger.plot_granger( granger_outs ...
  , 'mask_func', mask_func ...
  , 'plot_time_series', true ...
  , 'plot_average', false ...
  , 'epoch_granger_value_threshold', 20 ...
  , 'epoch_window_offset', 1 ...
  , 'max_num_epoch_windows', 5 ...
);