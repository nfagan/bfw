conf = bfw.config.load();
conf = bfw.set_dataroot( fullfile(conf.PATHS.mount, bfw_image_task_data_root()), conf );

%%

active_dates = bfw_it.active_dates_from_day_info( [], conf );

rect_pad = 0;
use_roi = 'image';

% rect_pad = 0.05;
% use_roi = 'eyes';

fix_outs = bfw_image_task_stim_fixations( ...
    'files_containing', active_dates ...
  , 'use_image_offset', true ...
  , 'config', conf ...
  , 'rect_padding', rect_pad ...
  , 'roi', use_roi ...
);

%%

bfw_it.plot_fix_info( fix_outs ...
  , 'do_save', true ...
  , 'config', conf ...
  , 'base_subdir', use_roi ...
);

%%

bfw_it.plot_fix_info_over_time( fix_outs ...
  , 'do_save', true ...
  , 'config', conf ...
  , 'base_subdir', use_roi ...
);