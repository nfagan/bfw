function raw_event_outs = bfw_make_raw_recording_events(varargin)

% use more accurate fixation detection for non-stimulation days
event_defaults = bfw_recording_event_defaults();

raw_event_outs = bfw.make_raw_events( event_defaults, varargin{:} );

try
  bfw.make_reformatted_raw_events( varargin{:} );
catch err
  warning( err.message );
end

end