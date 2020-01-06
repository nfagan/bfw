function bfw_events_pipeline(varargin)

%   BFW_EVENTS_PIPELINE -- Make events.

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

try
  sessions = bfw.get_sessions_by_stim_type( params.config );
catch err
  throw( err );
end

handle_bounds( params, sessions );

bfw.make_aligned_samples( params );
bfw.make_binned_aligned_samples( params );

handle_events( params, sessions );

end

function sessions = intersect_sessions(in_files_containing, required_sessions)

if ( isempty(in_files_containing) )
  sessions = required_sessions;
else
  sessions = intersect( in_files_containing, required_sessions );
end

end

function handle_events(params, sessions)

stim_sessions = union( sessions.m1_exclusive_sessions, sessions.m1_radius_sessions );
no_stim_sessions = sessions.no_stim_sessions;

stim_session_files = intersect_sessions( params.files_containing, stim_sessions );
no_stim_session_files = intersect_sessions( params.files_containing, no_stim_sessions );

bfw_make_raw_stimulation_events( params, 'files_containing', stim_session_files );
bfw_make_raw_recording_events( params, 'files_containing', no_stim_session_files );

end

function handle_bounds(params, sessions)

% on no stim (just recording) sessions, no padding applied to eyes.
bfw.make_raw_bounds( params ...
  , 'files_containing', sessions.no_stim_sessions ...
  , 'padding', 0 ...
);

% on stim sessions to eyes, 5% padding applied to eyes, to match the 
% arduino's eyes roi.
bfw.make_raw_bounds( params ...
  , 'files_containing', sessions.m1_exclusive_sessions ...
  , 'padding', struct('eyes_nf', 0.05) ...
);

% on stim sessions to non-eyes, -5% padding to eyes, to match the arduino's
% non-eyes roi.
bfw.make_raw_bounds( params ...
  , 'files_containing', sessions.m1_radius_sessions ...
  , 'padding', struct('eyes_nf', -0.05) ...
);

% bfw.adjust.add_raw_face_non_eyes( params, 'overwrite', true );

end