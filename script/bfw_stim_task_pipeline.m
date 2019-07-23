function bfw_stim_task_pipeline(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw.set_dataroot( bfw_stim_task_data_root(), bfw.config.load() );
defaults.skip_existing = true;

params = bfw.parsestruct( defaults, varargin );

folders = find_new_subfolders( params.config );

%%  unified

bfw.make_unified( folders, params );
bfw.make_meta( params );
bfw.make_stim_meta( params );

%%  plex sync + stim

bfw.make_sync_times( params );
bfw.make_stimulation_times( params );

%%  edfs

bfw.make_edfs( params );
bfw.make_edf_raw_samples( params );
bfw.make_edf_sync_times( params );

%%  plex time

bfw.make_plex_raw_time( params );

%%  align indices

%   this takes a long time.
bfw.make_raw_aligned_indices( params );

%%  rois + bounds

bfw.make_raw_rois( params );

bfw.make_raw_bounds( params ...
  , 'padding', 0 ...
);

%%  fixations

bfw.make_raw_eye_mmv_fixations( params ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

bfw.make_raw_arduino_fixations( params );

%%  aligned + binned aligned samples (using aligned indices)

bfw.make_aligned_samples( params );
bfw.make_binned_aligned_samples( params );

%%  events

bfw_events_pipeline( params );

end

function names = find_new_subfolders(conf)

raw_p = fullfile( bfw.dataroot(conf), 'raw' );
subfolder_names = shared_utils.io.filenames( shared_utils.io.find(raw_p, 'folders') );

unified_p = bfw.gid( 'unified', conf );

if ( ~shared_utils.io.dexists(unified_p) )
  names = subfolder_names;
else
  current_unified_files = shared_utils.io.findmat( unified_p );
  
end

end
