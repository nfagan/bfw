% folders = { '02082018', '02092018' };
% file_spec = folders;
% 
% shared_inputs = { 'files_containing', file_spec, 'overwrite', true };

%   if just wanting to re-process all files:
shared_inputs = { 'overwrite', true };

addpath( '~/Documents/MATLAB/repositories/bfw' );
bfw.add_depends();

%%  unified

bfw.make_unified( folders );

%%  sync times

bfw.make_sync_times( shared_inputs{:} );

%%  edfs
 
bfw.make_edfs( shared_inputs{:} );

%%  blink info

bfw.make_edf_blink_info( shared_inputs{:} );

%%  aligned

bfw.make_edf_aligned( shared_inputs{:} );

%% add plex time

bfw.adjust.add_plex_time_to_aligned;

%%  fixations

% bfw.make_edf_fixations( shared_inputs{:} );
bfw.make_eye_mmv_fixations( shared_inputs{:} ...
  , 't1', 20 ...
  , 't2', 10 ...
  , 'min_duration', 0.03 ...
);

%%  restrict fixations to at least N ms

% bfw.adjust.set_fixation_criterion( shared_inputs{:} ...
%   , 'duration', 10 ... % remove fixations less than n ms.
% );

%%  rois

bfw.make_rois( shared_inputs{:} );

%%  bounds

%   `require_fixation` -- if true, bounds will be set false if the monkey
%    is not fixating at a given time-point, even if they are technically
%    in the roi boundary.

bfw.make_bounds( shared_inputs{:} ...
  , 'window_size', 10 ...
  , 'step_size', 10 ...
  , 'remove_blink_nans', true ...
  , 'require_fixation', true ...
  , 'single_roi_fixations', false...
);
% addpath('/Users/chuchengchi/Desktop/CC analysis/tmp');
% varargin = {shared_inputs{:}, 'window_size', 10, 'step_size', 10, 'remove_blink_nans', true, 'require_fixation', true}; 
% bfw.make_bounds
%   separate eyes from face
% bfw.adjust.separate_eyes_from_face( shared_inputs{:} );
% bfw.adjust.separate_mouth_from_face( shared_inputs{:} );

%%  events

bfw.make_events( shared_inputs{:} ...
  , 'duration', 10 ...              %   minimum duration for an event to register.
  , 'plus_minus_duration', 50 ...
  , 'mutual_method','plus-minus' ...
  , 'fill_gaps', true ...
  , 'fill_gaps_duration', 150 ...   %   minimum inter-event duration
);



% %   classify events as m1 leading m2, vs. m2 leading m1
% bfw.adjust.add_m_ordering( shared_inputs{:} ...
%   , 'max_lag', 2 ...
% );

%   convert to plexon time
bfw.adjust.events_to_plex_time( shared_inputs{:} );

%   concatenate events within day
bfw.make_events_per_day( shared_inputs{:} );

%%  spikes

% bfw.make_spikes( shared_inputs{:} );
bfw.make_ms_spikes( shared_inputs{:} );

%%  event aligned spikes

bfw.make_aligned_spikes( shared_inputs{:} ...
  , 'psth_bin_size', 0.01 ...
  );

%%  lfp

bfw.make_lfp( shared_inputs{:} );

%%  event aligned lfp

bfw.make_aligned_lfp( shared_inputs{:} );

%%  modulation type

bfw.make_modulation_type( shared_inputs{:} ...
  , 'psth_bin_size', 0.01 ...
  , 'look_back', -0.5 ...
  , 'look_ahead', 0.5 ...
  , 'window_pre', [-0.3, 0] ...
  , 'window_post', [0, 0.3] ...
);