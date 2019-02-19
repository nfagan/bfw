function bfw_make_raw_recording_events(varargin)

% use more accurate fixation detection for non-stimulation days
event_defaults = bfw_recording_event_defaults();

bfw.make_raw_events( event_defaults, varargin{:} );
bfw.make_reformatted_raw_events( varargin{:} );

end