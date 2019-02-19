function bfw_make_raw_stimulation_events(varargin)

% use arduino-fixation detection for stimulation days.
event_defaults = bfw_stimulation_event_defaults();

bfw.make_raw_events( event_defaults, varargin{:} );
bfw.make_reformatted_raw_events( varargin{:} );

end