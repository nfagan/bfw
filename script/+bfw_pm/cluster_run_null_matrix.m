function cluster_run_null_matrix(varargin)

defaults = bfw_pm.null_matrix_defaults();
params = bfw.parsestruct( defaults, varargin );

spike_data = bfw_pm.load_spike_data( bfw.dataroot() );
spike_labels = fcat.from( spike_data.save_spike_labels );

pm_outs = bfw_pm.null_matrix( spike_data.spike_dat, spike_labels, spike_data.t ...
  , 'iters', 1e3 ...
  , params ...
);

save_p = fullfile( bfw.dataroot(), 'analyses', 'spike_rate', 'out', dsp3.datedir() );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, 'population_matrix.mat'), 'pm_outs', '-v7.3' );

end