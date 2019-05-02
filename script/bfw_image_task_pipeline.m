function bfw_image_task_pipeline(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config.PATHS.data_root = '/media/chang/T41/data/bfw/image-task/';
defaults.skip_existing = true;

inputs = bfw.parsestruct( defaults, varargin );

%%

bfw.make_unified( {'04262019', '04282019', '04302019'}, inputs );

bfw.make_meta( inputs );
bfw.make_stim_meta( inputs );

%%  plex sync + stim

bfw.make_sync_times( inputs );
bfw.make_stimulation_times( inputs );

%%  task events

bfw.make_image_task_events( inputs );

%%  edfs

bfw.make_edfs( inputs );
bfw.make_edf_raw_samples( inputs );
bfw.make_edf_sync_times( inputs );

%%  plex time

bfw.make_plex_raw_time( inputs );

%%  align indices

%   this takes a long time.
bfw.make_raw_aligned_indices( inputs );

%%

bfw.make_raw_eye_mmv_fixations( inputs ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

bfw.make_raw_arduino_fixations( inputs );

%%

bfw.make_aligned_samples( inputs );
bfw.make_binned_aligned_samples( inputs );

end
