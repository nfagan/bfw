function make_raw_events(varargin)

import shared_utils.io.fload;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.duration = nan;  % ms
defaults.require_fixations = true;
defaults.fixations_subdir = 'eye_mmv_fixations';
defaults.samples_subdir = 'aligned_binned_raw_samples';
defaults.fill_gaps = false;
defaults.fill_gaps_duration = nan;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;
fsd = params.fixations_subdir;
ssd = params.samples_subdir;

aligned_samples_p = bfw.gid( ff(ssd, isd), conf );

time_p = ff( aligned_samples_p, 'time' );
bounds_p = ff( aligned_samples_p, 'bounds' );
fixations_p = ff( aligned_samples_p, fsd );

events_p = bfw.gid( ff('raw_events', osd), conf );

mats = bfw.require_intermediate_mats( params.files, time_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  time_file = fload( mats{i} );
  
  unified_filename = time_file.unified_filename;
  output_filename = fullfile( events_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    bounds_file = fload( fullfile(bounds_p, unified_filename) );
    fix_file = fload( fullfile(fixations_p, unified_filename) ); 
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  t = time_file.t;
  
  %   Check whether to adjust the duration to match the given bin size.
  if ( bounds_file.params.is_binned )
    step_size = bounds_file.params.step_size;
  else
    step_size = 1;
  end
  
  monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
  first_id = monk_ids{1};
  roi_names = keys( bounds_file.(first_id) );
  
  has_mutual_events = numel( monk_ids ) > 1;
  mutual_evts = [];
  
  events_file = struct();
  events_file.unified_filename = unified_filename;
  events_file.params = params;
  events_file.params.step_size = step_size;
  
  events_file.events = [];
  events_file.labels = {};
  
  success = true;
  
  for j = 1:numel(roi_names)
    roi = roi_names{j};
    
    try
      exclusive_evts = find_exclusive_events( roi, t, step_size, bounds_file, fix_file, params );
      
      if ( has_mutual_events )
        mutual_evts = find_mutual_events( t, step_size, exclusive_evts, params ); 
      end
      
      joined = join_events( exclusive_evts, mutual_evts );
      repeated_roi = repmat( {roi}, rows(joined.events), 1 );
      
      events_file.events = [ events_file.events; joined.events ];
      events_file.labels = [ events_file.labels; [joined.labels, repeated_roi] ];
      
      if ( j == 1 )
        events_file.event_key = joined.event_key;
        events_file.categories = cshorzcat( joined.categories, 'roi' );
      end
      
    catch err
      bfw.print_fail_warn( unified_filename, err.message );
      success = false;
      break;
    end
  end
  
  if ( ~success )
    continue;
  end
  
  shared_utils.io.require_dir( events_p );
  shared_utils.io.psave( output_filename, events_file, 'events_file' );
end

end

function outs = join_events(exclusive, mutual)

monk_ids = intersect( {'m1', 'm2'}, fieldnames(exclusive) );

all_event_info = [];
labels = {};

if ( ~isempty(mutual) )
  %   Ensure that exclusive events are not also contained in mutual events
  %   (i.e., that exclusive events are truly exclusive)
  
  mut_events = mutual.events(:, mutual.event_key('start_index'));
  progenitors = cell( size(mut_events) );
  got_progenitor = false( size(mut_events) );
  
  for i = 1:numel(monk_ids)
    monk_id = monk_ids{i};
    
    events = exclusive.(monk_id).events(:, exclusive.(monk_id).event_key('start_index'));
    is_duplicate = ismember( events, mut_events );
    
    exclusive.(monk_id).events(is_duplicate, :) = [];
    
    is_matching = ismember( mut_events, events );
    
    %   The progenitor is subject that initiated the event. This is *not*
    %   the subject for which the exclusive event time matches the mutual
    %   time, but rather the other subject.
    progen = char( setdiff(monk_ids, monk_id) );
    
    got_progenitor(is_matching) = true;
    progenitors(is_matching) = { sprintf('%s_initiated', progen) };
  end
  
  assert( all(got_progenitor), 'Some mutual events did not have a progenitor.' );
  
  all_event_info = mutual.events;
  looks_by = repmat( {'mutual'}, rows(all_event_info), 1 );
  event_type = repmat( {'mutual_event'}, size(looks_by) );
  
  labels = [ labels; [looks_by, progenitors, event_type] ];
end

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  event_info = exclusive.(monk_id).events;
  looks_by = repmat( monk_ids(i), rows(event_info), 1 );
  progenitor = repmat( {'<initiator>'}, rows(event_info), 1 );
  event_type = repmat( {'exclusive_event'}, size(progenitor) );
  
  all_event_info = [ all_event_info; event_info ];
  labels = [ labels; [looks_by, progenitor, event_type] ];
end

outs = struct();
outs.events = all_event_info;
outs.event_key = exclusive.(monk_ids{1}).event_key;
outs.labels = labels;
outs.categories = { 'looks_by', 'initiator', 'event_type' };

end

function outs = find_mutual_events(t, step_size, exclusive_outs, params)

import shared_utils.logical.find_starts;

duration = ceil( params.duration / step_size );
assert( ~isnan(duration), '"duration" cannot be nan.' );

is_valid_a = exclusive_outs.m1.is_valid;
is_valid_b = exclusive_outs.m2.is_valid;

is_valid = is_valid_a & is_valid_b;

evts = find_starts( is_valid, duration );

if ( params.fill_gaps )
  fill_gaps_duration = ceil( params.fill_gaps_duration / step_size );

  assert( ~isnan(fill_gaps_duration), '"fill_gaps_duration" cannot be nan.' );

  [is_valid, evts] = bfw.fill_gaps( is_valid, evts, fill_gaps_duration );
end

evt_info = get_event_info( t, evts, is_valid, duration );

outs.events = evt_info;
outs.event_key = get_event_key();
outs.is_valid = is_valid;

end

function exclusive_outs = find_exclusive_events(roi_name, t, step_size, bounds_file, fix_file, params)

import shared_utils.vector.slidebin;
import shared_utils.logical.find_starts;

duration = ceil( params.duration / step_size );
assert( ~isnan(duration), '"duration" cannot be nan.' );

monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );

exclusive_outs = struct();

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  bounds = bounds_file.(monk_id);
  is_fix = fix_file.(monk_id);

  is_valid_sample = bounds(roi_name);

  if ( params.require_fixations )
    is_valid_sample = is_valid_sample & is_fix;
  end

  evts = find_starts( is_valid_sample, duration );

  if ( params.fill_gaps )
    fill_gaps_duration = ceil( params.fill_gaps_duration / step_size );

    assert( ~isnan(fill_gaps_duration), '"fill_gaps_duration" cannot be nan.' );

    [is_valid_sample, evts] = bfw.fill_gaps( is_valid_sample, evts, fill_gaps_duration );
  end

  evt_info = get_event_info( t, evts, is_valid_sample, duration );

  outs.events = evt_info;
  outs.event_key = get_event_key();
  outs.is_valid = is_valid_sample;
  
  exclusive_outs.(monk_id) = outs;
end

end

function evt_key = get_event_key()

evt_key = containers.Map();
evt_key('start_index') = 1;
evt_key('stop_index') = 2;
evt_key('length') = 3;
evt_key('start_time') = 4;
evt_key('stop_time') = 5;
evt_key('duration') = 6;

end

function evt_info = get_event_info(t, evts, is_valid_sample, duration)

[evts, evt_stops, evt_lengths] = get_event_lengths( t, evts, is_valid_sample, duration );

evt_start_times = columnize( t(evts) );
evt_stop_times = columnize(t(evt_stops));
evt_durations = evt_stop_times - evt_start_times;

evt_info = [ evts, evt_stops, evt_lengths, evt_start_times, evt_stop_times, evt_durations ];
end

function [evts, evt_stops, evt_lengths] = get_event_lengths(t, evts, is_valid_sample, duration)

evts = columnize( evts );
evt_lengths = arrayfun( @(x) get_event_length(x, is_valid_sample), evts );   
evt_stops = evts + evt_lengths;

%   Check whether any events do not stop before the end of the time vector.
%   In this case, decide whether to exclude the event, or mark its end as
%   the last time point. The event will be included if its length is at
%   least `duration` + 1; i.e., if truncating the event stop to the end of
%   the time vector does not shorten the event to be below the given
%   duration threshold.
out_of_bounds = evt_stops > numel( t );

if ( any(out_of_bounds) )
  oob_ind = find( out_of_bounds );

  for k = 1:numel(oob_ind)
    ind = oob_ind(k);
    
    if ( evt_lengths(ind) - 1 >= duration )
      evt_lengths(ind) = evt_lengths(ind) - 1;
      evt_stops(ind) = evt_stops(ind) - 1;
      out_of_bounds(ind) = false;
    end
  end
end

evts(out_of_bounds) = [];
evt_lengths(out_of_bounds) = [];
evt_stops(out_of_bounds) = [];

end

function l = get_event_length(index, bounds)
l = 0;
while ( index+l <= numel(bounds) && bounds(index+l) ), l = l + 1; end
end