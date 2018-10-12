conf = bfw.config.load();

inputs = struct();
inputs.config = conf;
inputs.input_subdir = '';
inputs.output_subdir = '';
inputs.overwrite = false;
inputs.files_containing = '09072018_position_10';

%%  unified

bfw.make_unified( folders, inputs );
bfw.make_meta( inputs );

%%  plex sync + stim

bfw.make_sync_times( inputs );
bfw.make_stimulation_times( inputs );

%%  edfs

bfw.make_edfs( inputs );
bfw.make_edf_raw_samples( inputs );
bfw.make_edf_sync_times( inputs );
% bfw.make_edf_blink_info( shared_inputs{:} );

%%  rois + bounds

bfw.make_rois( inputs );

bfw.make_raw_bounds( inputs ...
  , 'padding', 0 ...
);

%%  plex time

bfw.make_plex_raw_time( inputs );

%%  fixations

bfw.make_raw_eye_mmv_fixations( inputs ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

bfw.make_raw_arduino_fixations( inputs );

%%  align indices

%   this takes a long time.
bfw.make_raw_aligned_indices( inputs );

%%  aligned + binned aligned samples (using aligned indices)

sample_kinds = { 'time', 'position', 'bounds', 'eye_mmv_fixations', 'arduino_fixations' };

bfw.make_raw_aligned( inputs ...
  , 'kinds', sample_kinds ...
);

bfw.make_binned_raw_aligned( inputs ...
  , 'kinds', sample_kinds ...
);

%%  events

bfw.make_raw_events( inputs ...
  , 'duration', 10 ...
  , 'fill_gaps', true ...
  , 'fill_gaps_duration', 150 ...
);

%   formats data consistent with `make_events`
bfw.make_reformatted_raw_events( inputs );
