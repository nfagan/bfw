conf = bfw.config.load();

repadd( 'chronux', true );
repadd( 'bfw/script' );

if ( isempty(gcp('nocreate')) )
  parpool( feature('numcores') );
end

%%

ps = bfw.matched_files( ...
    shared_utils.io.findmat(bfw.gid('meta', conf)) ...
  , bfw.gid('aligned_raw_samples/time', conf) ...
);

evt_labels = fcat();
evts = [];

bin_step = 0.5;

for i = 1:size(ps, 1)
  t_file = shared_utils.io.fload( ps{i, 2} );
  meta_file = shared_utils.io.fload( ps{i, 1} );
  
  start_t = t_file.t(find(~isnan(t_file.t), 1));
  stop_t = t_file.t(find(~isnan(t_file.t), 1, 'last'));  
  t_series = start_t:bin_step:stop_t;
  
  labs = bfw.struct2fcat( meta_file );
  repmat( labs, numel(t_series) );
  time_point_labels = arrayfun( ...
    @(x) sprintf('tp-%d', x), 1:numel(t_series), 'un', 0 );
  addsetcat( labs, 'time-point', time_point_labels );
  
  evts = [ evts; t_series(:) ];
  append( evt_labels, labs );
end

assert_ispair( evts, evt_labels );

%%

bfw_revisit_sfcoherence_per_session( evts, evt_labels, 'task_type' ...
  , 'config', conf ...
  , 'min_t', 0 ...
  , 'max_t', 0 ...
);