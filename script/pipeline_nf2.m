conf = bfw.config.load();

inputs = struct();
inputs.config = conf;
inputs.input_subdir = '';
inputs.output_subdir = '';
inputs.overwrite = false;
inputs.files_containing = '';
inputs.files_not_containing = '';

folders = {};

%%  unified

bfw.make_unified( folders, inputs );
bfw.make_meta( inputs );
bfw.make_stim_meta( inputs );

%%  plex sync + stim

bfw.make_sync_times( inputs );
bfw.make_stimulation_times( inputs );

%%  edfs

bfw.make_edfs( inputs );
bfw.make_edf_raw_samples( inputs );
bfw.make_edf_sync_times( inputs );

%%  plex time

bfw.make_plex_raw_time( inputs );

%%  align indices

%   this takes a long time.
bfw.make_raw_aligned_indices( inputs );

%%  rois + bounds

bfw.make_raw_rois( inputs );

bfw.make_raw_bounds( inputs ...
  , 'padding', 0 ...
);

%%  fixations

bfw.make_raw_eye_mmv_fixations( inputs ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

bfw.make_raw_arduino_fixations( inputs );

%%  aligned + binned aligned samples (using aligned indices)

bfw.make_aligned_samples( inputs );
bfw.make_binned_aligned_samples( inputs );

%%  events

bfw.make_raw_events( inputs ...
  , 'duration', 10 ...
  , 'fill_gaps', true ...
  , 'fill_gaps_duration', 150 ...
  , 'samples_subdir', 'aligned_binned_raw_samples' ...
  , 'fixations_subdir', 'arduino_fixations' ...
);

%   formats data consistent with `make_events`
bfw.make_reformatted_raw_events( inputs );

%%  lfp

bfw.make_rng( inputs );
bfw.make_lfp( inputs );
bfw.make_raw_aligned_lfp( inputs );

bfw.make_raw_coherence( inputs );
bfw.make_raw_mtpower( inputs );

bfw.make_raw_summarized_measure( inputs ...
  , 'measure', 'raw_coherence' ...
);

bfw.make_raw_summarized_measure( inputs ...
  , 'measure', 'raw_mtpower' ...
);
