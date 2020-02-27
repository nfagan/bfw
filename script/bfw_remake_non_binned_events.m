%%  Bounds file based.

rois = { 'eyes_nf', 'face', 'left_nonsocial_object', 'right_nonsocial_object', 'everywhere' };

bfw_make_raw_recording_events( ...
    'save', true ...
  , 'append', false ...
  , 'skip_existing', false ...
  , 'samples_subdir', 'aligned_raw_samples' ...
  , 'use_bounds_file_for_rois', true ...
  , 'check_accept_mutual_event_func', @bfw.default_check_accept_mutual_event_func ...
  , 'duration', 10 ...
  , 'rois', rois ...
);

%%  Non-bounds file based.

bfw_make_raw_recording_events( ...
    'save', true ...
  , 'is_parallel', true ...
  , 'append', false ...
  , 'skip_existing', false ...
  , 'samples_subdir', 'aligned_raw_samples' ...
  , 'use_bounds_file_for_rois', false ...
  , 'check_accept_mutual_event_func', @bfw.default_check_accept_mutual_event_func ...
  , 'allow_keep_initiating_exclusive_event', false ...
  , 'duration', 70 ...
);