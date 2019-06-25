%%  1a) Edit rois in bfw.make.rois -- add a calibration function for each new roi.

% cd /media/chang/T2/data/bfw/intermediates/rois
% mkdir <foldername>
% cp *.mat ./<foldername>

% Fill in new roi names
use_rois = { 'right_middle_nonsocial_object' };

inputs = struct();

% Default config file.
inputs.config = bfw.config.load();
% Must be true to allow overwriting of the existing file, even though
% the exsting contents will be preserved.
inputs.overwrite = true;
% Load existing data, add rois to the existing file.
inputs.append = true;

%%

% Updates the rois + bounds
bfw.make_raw_rois( inputs, 'rois', use_rois );
bfw.make_raw_bounds( inputs, 'rois', use_rois );

%%

bfw.make_aligned_bounds( inputs );
bfw.make_binned_aligned_bounds( inputs );

%%

sessions = bfw.get_sessions_by_stim_type( inputs.config );
no_stim_sessions = sessions.no_stim_sessions;

event_defaults = bfw_recording_event_defaults();

bfw.make_raw_events( event_defaults, inputs, 'rois', use_rois, 'files_containing', no_stim_sessions );
bfw.make_reformatted_raw_events( inputs, 'files_containing', no_stim_sessions );
