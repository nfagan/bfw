folders = { '02022018', '02042018' };
file_spec = folders;

shared_inputs = { 'files_containing', file_spec, 'overwrite', false };

%%  unified

bfw.make_unified( folders );

%%  edfs

bfw.make_edfs( shared_inputs{:} );

%%  blink info

bfw.make_edf_blink_info( shared_inputs{:} );

%%  aligned

bfw.make_edf_aligned( shared_inputs{:} );

%%  rois

bfw.make_rois( shared_inputs{:} );

%%  bounds

bfw.make_bounds( shared_inputs{:} ...
  , 'window_size', 500 ...
  , 'step_size', 10 ...
  , 'remove_blink_nans', true ...
);

%   separate eyes from face
bfw.adjust.separate_eyes_from_face( shared_inputs{:} );

%%  events

bfw.make_events( shared_inputs{:} ...
  , 'duration', 10 ...
);

%   classify events as m1 leading m2, vs. m2 leading m1
bfw.adjust.add_m_ordering( shared_inputs{:} ...
  , 'max_lag', 2 ...
);

%%  spikes

bfw.make_spikes( shared_inputs{:} );

%%  event aligned spikes

bfw.make_event_aligned_spikes( shared_inputs{:} ...
  , 'psth_bin_size', 0.05 ...
  , 'compute_null', false ...
  );

%%  lfp

bfw.make_lfp( shared_inputs{:} );