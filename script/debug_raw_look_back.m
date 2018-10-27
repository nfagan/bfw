function outs = debug_raw_look_back(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.is_old_events = false;
defaults.look_back = -1;
defaults.look_ahead = 5;
defaults.keep_within_threshold = 0.3;
defaults.samples_subdir = 'aligned_binned_raw_samples';
defaults.include_samples = false;
defaults.use_stop_time = true;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
is_old_events = params.is_old_events;

event_subdir = ternary( is_old_events, 'events', 'raw_events' );
samples_subdir = params.samples_subdir;

stim_p =    bfw.gid( 'stim', conf );
meta_p =    bfw.gid( 'meta', conf );
events_p =  bfw.gid( event_subdir, conf );
samples_p = bfw.gid( samples_subdir, conf );
roi_p =     bfw.gid( 'rois', conf );

stim_mats = bfw.require_intermediate_mats( params.files, stim_p, params.files_containing );

s = [ 1, numel(stim_mats) ];
all_labs = cell( s );
all_traces = cell( s );
all_to_keep = cell( s );
all_offsets = cell( s );
all_ts = cell( s );
all_samples = cell( s );
all_distances = cell( s );
all_eye_bounds = cell( s );

is_valid = true( s );

look_back = params.look_back;
look_ahead = params.look_ahead;

keep_thresh = params.keep_within_threshold;

for idx = 1:numel(stim_mats)
  shared_utils.general.progress( idx, numel(stim_mats) );
  
  stim_file = shared_utils.io.fload( stim_mats{idx} );

  un_filename = stim_file.unified_filename;
  
  %   dummy; see: https://www.mathworks.com/matlabcentral/answers/422906-parfor-loop-with-continue-gives-incorrect-results
  if ( false ), is_valid(idx); end %#ok
  
  try
    events_file = fload( fullfile(events_p, un_filename) );
    time_file =   fload( fullfile(samples_p, 'time', un_filename) );
    bounds_file = fload( fullfile(samples_p, 'bounds', un_filename) );
    meta_file =   fload( fullfile(meta_p, un_filename) );
    roi_file =    fload( fullfile(roi_p, un_filename) );
    
    if ( params.include_samples )
      position_file = fload( fullfile(samples_p, 'position', un_filename) );
    end
  catch err
    bfw.print_fail_warn( un_filename, err.message );
    is_valid(idx) = false;
    continue;
  end
  
  if ( is_old_events )
    events_file = bfw.get_reformatted_events( events_file );
  end
  
  event_labs = fcat.from( events_file.labels, events_file.categories );
  event_info = events_file.events;
  
  start_time_col = events_file.event_key('start_time');
  stop_time_col = events_file.event_key('stop_time');
  length_col = events_file.event_key('length');
  start_index_col = events_file.event_key('start_index');
  stop_index_col = events_file.event_key('stop_index');
  
  t = time_file.t;
  
  look_mask = find( event_labs, {'m1'} );
  [look_labs, I, C] = keepeach( event_labs', {'roi', 'looks_by'}, look_mask );
  
  tmp_traces = [];
  tmp_ib_eyes = [];
  tmp_keep = [];
  tmp_offsets = [];
  tmp_labs = fcat();
  tmp_samples = {};
  tmp_distances = [];
  
  sr = 1 / (1e3/events_file.params.step_size);

  plot_t = look_back:sr:look_ahead;

  stim_times = stim_file.stimulation_times;
  sham_times = stim_file.sham_times;

  all_stim_times = [ stim_times(:); sham_times(:) ];
  
  stim_uuids = arrayfun( @(x) shared_utils.general.uuid() ...
    , 1:numel(all_stim_times), 'un', 0 );
  
  assert( numel(unique(stim_uuids)) == numel(all_stim_times) );
  
  for k = 1:numel(I)
    
    evt_ind = I{k};
    monk_id = C{2, k};
    
    subset_event_info = event_info(evt_ind, :);

    all_ib = zeros( numel(all_stim_times), numel(plot_t) );
    all_ib_eyes = zeros( size(all_ib) );
    to_keep = rowones( numel(all_stim_times), 'logical' );
    offsets = rowzeros( numel(all_stim_times) );
    stim_distances = nan( size(offsets) );
    
    positions = cell( size(to_keep) );
    timestamps = cell( size(positions) );

    if ( isempty(all_stim_times) )
      continue;
    end
    
    if ( params.include_samples )
      pos = position_file.(monk_id);
      
      bounds = bounds_file.(monk_id);
      eye_bounds = bounds('eyes_nf');
    end

    for i = 1:numel(all_stim_times)
      evts = subset_event_info(:, start_time_col);
      
      current_stim_time = all_stim_times(i);

      nearest_stim_time_idx = shared_utils.sync.nearest( t, current_stim_time );
      nearest_stim_time = t(nearest_stim_time_idx); 

      range_times = plot_t + nearest_stim_time;
      evt_idx = find( evts >= range_times(1) & evts <= range_times(end) );

      evts_in_range = evts(evt_idx);
      evt_lengths_in_range = subset_event_info(evt_idx, length_col);
      evt_stops_in_range = subset_event_info(evt_idx, stop_time_col);
      evt_start_indices_in_range = subset_event_info(evt_idx, start_index_col);
      evt_stop_indices_in_range = subset_event_info(evt_idx, stop_index_col);

      nearest_evt_idx = shared_utils.sync.nearest( range_times, evts_in_range );
      nearest_evt_stop_idx = shared_utils.sync.nearest( range_times, evt_stops_in_range );

      nearest_stim_idx_after_evt = shared_utils.sync.nearest_after( evts_in_range, current_stim_time );

      if ( nnz(nearest_stim_idx_after_evt) == 0 )
        to_keep(i) = false;
        continue;
      end
      
      stimulated_event_idx = evt_idx(nearest_stim_idx_after_evt);
      stimulated_event_time = evts(stimulated_event_idx);
      event_offset = current_stim_time - stimulated_event_time;

      to_keep(i) = event_offset < keep_thresh;
      offsets(i) = event_offset;
      
      if ( params.include_samples )
        timestamps{i} = cell( numel(nearest_evt_idx), 1 );
        positions{i} = cell( size(timestamps{i}) );
        
        stim_event_start = subset_event_info(stimulated_event_idx, start_index_col);
        
        stim_distances(i) = ...
          get_stimulated_event_distance_from_eyes( roi_file, position_file, stim_event_start );
      end

      for j = 1:numel(nearest_evt_idx)
        evt_start = nearest_evt_idx(j);
        
        if ( params.use_stop_time )
          evt_end = nearest_evt_stop_idx(j);
        else
          evt_end = evt_start + evt_lengths_in_range(j);
        end

        evt_end = min( evt_end, numel(plot_t) );
        evt_start = max( 1, evt_start );

        all_ib(i, evt_start:evt_end) = 1;
        
        if ( isnan(evt_start) || isnan(evt_stops_in_range(j)) )
          continue;
        end
        
        if ( params.include_samples )
          evt_start_idx = evt_start_indices_in_range(j);
          evt_stop_time = evt_stops_in_range(j);
          
          use_evt_stop = min( range_times(end), evt_stop_time );
          
          if ( use_evt_stop == evt_stop_time )
            evt_stop_idx = evt_stop_indices_in_range(j);
          else
            evt_stop_idx = shared_utils.sync.nearest( t, use_evt_stop );
          end
          
          first_t = range_times(min(nearest_evt_idx));
          start_t = t(evt_start_idx) - first_t;
          stop_t = t(evt_stop_idx) - first_t;
          
          positions{i}{j} = pos(:, [evt_start_idx, evt_stop_idx]);
          timestamps{i}{j} = [ start_t, stop_t ];
          
          all_ib_eyes(i, evt_start:evt_end) = eye_bounds(evt_start_idx:evt_stop_idx);
        end
      end
    end

    stim_labs = bfw.make_stim_labels( numel(stim_times), numel(sham_times) );
    join( stim_labs, fcat.from(struct2cell(meta_file)', fieldnames(meta_file)) );
    join( stim_labs, look_labs(k) );
    addsetcat( stim_labs, 'uuid', stim_uuids );
    
    tmp_traces = [ tmp_traces; all_ib ];
    tmp_ib_eyes = [ tmp_ib_eyes; all_ib_eyes ];
    tmp_keep = [ tmp_keep; to_keep ];
    tmp_offsets = [ tmp_offsets; offsets ];
    tmp_samples = [ tmp_samples; [timestamps, positions] ];
    tmp_distances = [ tmp_distances; stim_distances ];
    
    append( tmp_labs, stim_labs );
  end
  
  all_traces{idx} = tmp_traces;
  all_to_keep{idx} = tmp_keep;
  all_offsets{idx} = tmp_offsets;
  all_labs{idx} = tmp_labs;
  all_ts{idx} = plot_t;
  all_samples{idx} = tmp_samples;
  all_distances{idx} = tmp_distances;
  all_eye_bounds{idx} = tmp_ib_eyes;
end

outs = struct();

if ( numel(all_ts) > 0 )
  outs.t = all_ts{1};
else
  outs.t = [];
end

outs.labels = vertcat( fcat(), all_labs{is_valid} );
outs.traces = vertcat( all_traces{is_valid} );
outs.eye_bounds = vertcat( all_eye_bounds{is_valid} );
outs.is_within_threshold = vertcat( all_to_keep{is_valid} );
outs.event_offsets = vertcat( all_offsets{is_valid} );
outs.samples = vertcat( all_samples{is_valid} );
outs.samples_key = get_samples_key();
outs.stim_distances = vertcat( all_distances{:} );

end

function ib = get_bounds(t, range_times, start_times, stop_times, eye_bounds)

d = 10;

end

function d = get_stimulated_event_distance_from_eyes(roi_file, pos_file, stim_event_start)

eyes_roi = roi_file.m1.rects('eyes_nf');
pos = pos_file.m1;

eye_x = mean( eyes_roi([1, 3]) );
eye_y = mean( eyes_roi([2, 4]) );

eye_w = eyes_roi(3) - eyes_roi(1);

stim_x = pos(1, stim_event_start);
stim_y = pos(2, stim_event_start);

d = bfw.distance( eye_x, eye_y, stim_x, stim_y );

end

function m = get_samples_key()

m = containers.Map();
m('t') = 1;
m('position') = 2;

end