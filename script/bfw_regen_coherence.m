rois = { 'eyes_nf', 'face', 'right_nonsocial_object', 'right_nonsocial_object_eyes_nf_matched' };

conf = bfw.config.load();
lfp_p = bfw.gid( 'lfp', conf );
lfp_files = shared_utils.io.findmat( lfp_p );
lfp_files = lfp_files(contains(lfp_files, 'position_1.mat'));

dst_p = bfw.gid( 'coherence', conf );

max_f = 100;

for i = 18:numel(lfp_files)
  fprintf( '\n %d of %d', i, numel(lfp_files) );
  
  try
    lfp_file = shared_utils.io.fload( lfp_files{i} );
    events_file = shared_utils.io.fload( fullfile(bfw.gid('raw_events_remade', conf), lfp_file.unified_filename) );
    rng_file = shared_utils.io.fload( fullfile(bfw.gid('rng', conf), lfp_file.unified_filename) );
  catch err
    warning( err.message );
    continue
  end

  aligned_files = containers.Map( {'lfp', 'raw_events_remade'}, {lfp_file, events_file} );
  
  for j = 1:numel(rois)
    fprintf( '\n\t %d of %d', j, numel(rois) );
    
    aligned_file = bfw.make.raw_aligned_lfp( aligned_files ...
      , 'rois', rois{j} ...
      , 'events_subdir', 'raw_events_remade' ...
    );
  
    coh_files = containers.Map( ...
      {'raw_aligned_lfp', 'rng'}, {aligned_file, rng_file} );
    
    try
      coh_file = bfw.make.raw_coherence( coh_files ); 
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