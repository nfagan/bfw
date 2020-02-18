function defaults = raw_events(varargin)

%   RAW_EVENTS -- Get values for ... make.raw_events function.

defaults = bfw.get_common_make_defaults( varargin{:} );

% 'duration' gives the integer number of *ms* that is the minimum
% event-duration.
defaults.duration = nan;  % ms

% 'require_fixations' specifies whether to consider fixations in the event
% calculation. If this value is false, then events only depend on the eye
% being in bounds of a given roi.
defaults.require_fixations = true;

defaults.use_bounds_file_for_rois = true;
defaults.roi_order_func = @(roi_file) bfw.default_roi_ordering();
defaults.check_accept_mutual_event_func = @(varargin) deal( false, '' );

% 'fixations_subdir' gives the type of and intermediate directory containing 
% the fixations vector. Each subdirectory contains a file that is structured in
% the same way, but for which a different algorithm was used to consider a
% given sample as part of a fixation or not.
defaults.fixations_subdir = 'eye_mmv_fixations';

% 'samples_subdir' gives the intermediate directory containing time, 
% bounds, and fixation samples.
defaults.samples_subdir = 'aligned_binned_raw_samples';

% 'fill_gaps' indicates whether to merge events that are within a given
% number of ms of eachother.
defaults.fill_gaps = false;

% 'fill_gaps_duration' gives the integer number of ms between events below
% which those events will be merged into one. Only has an effect if
% 'fill_gaps' is true.
defaults.fill_gaps_duration = nan;

% 'is_truly_exclusive' indicates whether to strictly remove looking events
% for m1 or m2 that overlap in any amount with a mutual event. If this
% value is false, then, for a given mutual event, only the "exclusive"
% event that initiated the mutual event will be removed.
defaults.is_truly_exclusive = true;

defaults.calculate_mutual = true;

defaults.rois = 'all';
defaults.intermediate_directory_name = 'raw_events';
defaults.get_current_events_file_func = @bfw.make.util.get_saved_file_or_struct;

end