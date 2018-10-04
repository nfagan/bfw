folders = {};

files_containing = folders;

conf = bfw.config.load();

shared_inputs = { 'input_subdir', '', 'output_subdir', '' ...
  , 'files_containing', files_containing, 'overwrite', false, 'config', conf };

%%  unified

bfw.make_unified( folders, shared_inputs{:} );

%%  plex sync + stim

bfw.make_sync_times( shared_inputs{:} );
bfw.make_stimulation_times( shared_inputs{:} );

%%  edfs

bfw.make_edfs( shared_inputs{:} );
bfw.make_edf_raw_samples( shared_inputs{:} );
bfw.make_edf_sync_times( shared_inputs{:} );
% bfw.make_edf_blink_info( shared_inputs{:} );

%%  rois + bounds

bfw.make_rois( shared_inputs{:} );

bfw.make_bounds( shared_inputs{:} ...
  , 'padding', 0 ...
);

%%  plex time

bfw.make_plex_raw_time( shared_inputs{:} );

%%  aligned indices

bfw.make_raw_aligned_indices( shared_inputs{:} );

%%  fixations

bfw.make_raw_eye_mmv_fixations( shared_inputs{:} ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

bfw.make_raw_arduino_fixations( shared_inputs{:} );

%%  events

bfw.make_raw_events( shared_inputs{:} );
