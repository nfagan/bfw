rois = { 'eyes_nf', 'face', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' };

% conf = bfw.config.load();
lfp_p = bfw.gid( 'lfp', conf );
lfp_files = shared_utils.io.findmat( lfp_p );
lfp_files = lfp_files(contains(lfp_files, 'position_1.mat'));

dst_p = bfw.gid( 'sfcoherence', conf );

max_f = 100;

for i = 1:numel(lfp_files)
  fprintf( '\n %d of %d', i, numel(lfp_files) );
  
  try
    lfp_file = shared_utils.io.fload( lfp_files{i} );
    events_file = shared_utils.io.fload( fullfile(bfw.gid('raw_events_remade', conf), lfp_file.unified_filename) );
    rng_file = shared_utils.io.fload( fullfile(bfw.gid('rng', conf), lfp_file.unified_filename) );
    meta_file = shared_utils.io.fload( fullfile(bfw.gid('meta', conf), lfp_file.unified_filename) );
    spike_file = shared_utils.io.fload( fullfile(bfw.gid('cc_spikes', conf), lfp_file.unified_filename) );
  catch err
    warning( err.message );
    continue
  end
  
  %%
  
  event_ts = bfw.event_column( events_file, 'start_time' );
  event_labs = fcat.from( events_file );
  event_ts = event_ts(find(event_labs, 'eyes_nf'));
  
  pairs = [(1:2)', (2:3)'];
  [coh, f, t] = bfw.sfcoherence( {spike_file.data.times}, lfp_file.data, event_ts, pairs );
  
  %%

  coh_files = containers.Map( ...
      {'lfp', 'raw_events_remade', 'meta', 'cc_spikes'} ...
    , {lfp_file, events_file, meta_file, spike_file} );
  
  for j = 1:numel(rois)
    fprintf( '\n\t %d of %d', j, numel(rois) );
    
    params = bfw.make.defaults.raw_sfcoherence();
    mask_func = @(labels) find(labels, rois{j});
    params.keep_func = @(lfp, spikes) deal(mask_func(lfp), mask_func(spikes));
    params.events_subdir = 'raw_events_remade';
    params.rois = rois{j};
    params.verbose = true;
   
    try
      coh_file = bfw.make.raw_sfcoherence( coh_files, params );
    catch err
      warning( err.message );
      continue
    end
    
    keep_f = coh_file.f >= 0 & coh_file.f <= max_f;
    coh_file.data = coh_file.data(:, keep_f, :);
    coh_file.f = coh_file.f(keep_f);
    
    roi_dst_p = fullfile( dst_p, rois{j} );
    shared_utils.io.require_dir( roi_dst_p );
    
    roi_dst_p = fullfile( roi_dst_p, lfp_file.unified_filename );
    fprintf( '\n\t Saving %s', roi_dst_p );
    
    save( roi_dst_p, 'coh_file' );
  end
end