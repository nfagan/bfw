function bfw_make_raw_recording_events(varargin)

% use more accurate fixation detection for non-stimulation days
bfw.make_raw_events( ...
    'duration', 10 ...
  , 'fill_gaps', true ...
  , 'fill_gaps_duration', 150 ...
  , 'samples_subdir', 'aligned_binned_raw_samples' ...
  , 'fixations_subdir', 'eye_mmv_fixations' ...
  , varargin{:} ...
);

bfw.make_reformatted_raw_events( varargin{:} );

end