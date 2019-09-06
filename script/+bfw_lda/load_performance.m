function perf = load_performance(subdirs, conf)

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
end

load_p = fullfile( bfw.dataroot(conf), 'analyses', 'spike_lda', 'reward_gaze_spikes' ...
  , 'performance', subdirs{:}, 'performance.mat' );

if ( ~shared_utils.io.fexists(load_p) )
  error( 'Performance file does not exist in "%s".', fileparts(load_p) );
end

perf = load( load_p );

end