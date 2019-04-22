function bfw_run_roi_pair_spike_lda(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
params = bfw.parsestruct( defaults, varargin );

conf = params.config;
base_subdir = params.base_subdir;

lda_out = bfw_roi_pair_spike_lda( ...
    'null_iters', 100 ...
  , 'min_t', 0 ...
  , 'max_t', 400 ...
  , 'rois', {'eyes_nf', 'face', 'mouth', 'outside1'} ...
  , 'is_parallel', true ...
  , 'config', conf ...
);

use_subdir = sprintf( '%s_%s', base_subdir, dsp3.datedir );
save_p = fullfile( bfw.dataroot(conf), 'analyses', 'spike_lda', use_subdir );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, 'lda_out.mat'), 'lda_out' );

end