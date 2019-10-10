function [gc, gc_mask, params] = make_gaze_components(gaze_counts, gaze_data_type, varargin)

defaults = struct();
defaults.time_window = [0.05, 0.3];
defaults.nfix_window_dur = 10;
defaults.mask = rowmask( gaze_counts.labels );
defaults.windows = [];
defaults.is_empty_window = [];
defaults.empty_window_labels = fcat();
defaults.apply_empty_window_mask = false;

params = bfw.parsestruct( defaults, varargin );
gaze_data_type = validatestring( gaze_data_type, {'duration', 'nfix', 'total_nfix', 'spikes'} ...
  , mfilename, 'gaze data type' );

in_mask = params.mask;

start_times = bfw.event_column( gaze_counts, 'start_time' );
stop_times = bfw.event_column( gaze_counts, 'stop_time' );

if ( strcmp(gaze_data_type, 'total_nfix') && params.apply_empty_window_mask )
  in_mask = bfw.find_non_empty_windows( start_times, stop_times, gaze_counts.labels ...
    , params.windows, params.is_empty_window, params.empty_window_labels, in_mask );
end

gc_time_window = params.time_window;

gc = struct();

switch ( gaze_data_type )
  case 'duration'
    gc.psth = stop_times - start_times;
    gc.labels = gaze_counts.labels';
    gc.start_times = start_times;
    gc.stop_times = start_times;
    
  case 'nfix'
    window_dur = params.nfix_window_dur;
    [gc.psth, gc.labels, gc.start_times] = ...
      bfw_lda.windowed_num_fixations( gaze_counts, window_dur, nfix_each() );
    gc.stop_times = gc.start_times + window_dur;
    
  case 'total_nfix'
    [gc.psth, gc.labels] = bfw_lda.total_num_fixations( gaze_counts, total_nfix_each(), in_mask );
    gc.start_times = nan( rows(gc.psth), 1 );
    gc.stop_times = nan( rows(gc.psth), 1 );
    
  case 'spikes'
    gc.psth = nanmean( gaze_counts.spikes(:, gaze_counts.t >= gc_time_window(1) & gaze_counts.t <= gc_time_window(2)), 2 );
    gc.labels = gaze_counts.labels';
    gc.start_times = bfw.event_column( gaze_counts, 'start_time' ) + params.time_window(1);
    gc.stop_times = gc.start_times + params.time_window(2);
    
  otherwise
    error( 'Unrecognized gaze data type "%s".', gaze_data_type );
end

bfw.unify_single_region_labels( gc.labels );
gc.data_type = gaze_data_type;

if ( strcmp(gaze_data_type, 'total_nfix') || ~params.apply_empty_window_mask )
  gc_mask = rowmask( gc.labels );
else
  gc_mask = bfw.find_non_empty_windows( gc.start_times, gc.stop_times, gc.labels ...
    , params.windows, params.is_empty_window, params.empty_window_labels );
end

end

function each = total_nfix_each()

each = { 'region', 'session', 'unit_uuid', 'looks_by', 'event_type' };

end

function each = nfix_each()

each = { 'region', 'session', 'unit_uuid', 'unified_filename', 'looks_by', 'event_type' };

end