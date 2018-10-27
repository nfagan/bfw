function outs = bfw_stim_distance_vs_fixations(varargin)

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.is_old_events = false;
defaults.look_ahead = 2;
defaults.look_back = 0;
defaults.samples_subdir = 'aligned_binned_raw_samples';
defaults.selectors = { 'm1', 'eyes_nf' };

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
all_nfix = cell( s );
all_lookdur = cell( s );
all_distances = cell( s );

is_valid = true( s );

parfor idx = 1:numel(stim_mats)
  shared_utils.general.progress( idx, numel(stim_mats) );
  
  stim_file = shared_utils.io.fload( stim_mats{idx} );

  un_filename = stim_file.unified_filename;
  
  %   dummy; see: https://www.mathworks.com/matlabcentral/answers/422906-parfor-loop-with-continue-gives-incorrect-results
  if ( false ), is_valid(idx); end %#ok
  
  try
    events_file = fload( fullfile(events_p, un_filename) );
    time_file =   fload( fullfile(samples_p, 'time', un_filename) );
    meta_file =   fload( fullfile(meta_p, un_filename) );
    roi_file =    fload( fullfile(roi_p, un_filename) );
    position_file = fload( fullfile(samples_p, 'position', un_filename) );
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
  duration_col = events_file.event_key('duration');
  
  t = time_file.t;
  
  look_mask = find( event_labs, params.selectors );
  [look_labs, I] = keepeach( event_labs', {'roi', 'looks_by'}, look_mask );
  
  tmp_labs = fcat();
  tmp_n_fix = [];
  tmp_look_dur = [];
  tmp_distances = [];

  stim_times = stim_file.stimulation_times;
  sham_times = stim_file.sham_times;

  all_stim_times = [ stim_times(:); sham_times(:) ];
  
  stim_uuids = arrayfun( @(x) shared_utils.general.uuid() ...
    , 1:numel(all_stim_times), 'un', 0 );
  
  assert( numel(unique(stim_uuids)) == numel(all_stim_times) );
  
  for k = 1:numel(I)
    
    evt_ind = I{k};
    
    subset_event_info = event_info(evt_ind, :);

    stim_distances = nan( numel(all_stim_times), 1 );
    n_fixatons = rownan( rows(stim_distances) );
    look_dur = rownan( rows(stim_distances) );

    if ( isempty(all_stim_times) )
      continue;
    end

    for i = 1:numel(all_stim_times)
      evts = subset_event_info(:, start_time_col);
      
      current_stim_time = all_stim_times(i) + params.look_back;

      nearest_stim_time_idx = shared_utils.sync.nearest( t, current_stim_time );
      nearest_stim_time = t(nearest_stim_time_idx);
      
      max_look_ahead = nearest_stim_time + params.look_ahead;
      
      evt_idx = find( evts >= nearest_stim_time & evts <= max_look_ahead );
      
      evt_durs_in_range = subset_event_info(evt_idx, duration_col);
      look_dur(i) = sum( evt_durs_in_range );
      n_fixatons(i) = numel( evt_idx );
      
      stim_distances(i) = ...
          get_stimulated_event_distance_from_eyes( roi_file, position_file, nearest_stim_time_idx );
    end

    stim_labs = bfw.make_stim_labels( numel(stim_times), numel(sham_times) );
    join( stim_labs, fcat.from(struct2cell(meta_file)', fieldnames(meta_file)) );
    join( stim_labs, look_labs(k) );
    addsetcat( stim_labs, 'uuid', stim_uuids );
    
    append( tmp_labs, stim_labs );
    
    tmp_n_fix = [ tmp_n_fix; n_fixatons ];
    tmp_look_dur = [ tmp_look_dur; look_dur ];
    tmp_distances = [ tmp_distances; stim_distances ];
  end
  
  all_nfix{idx} = tmp_n_fix;
  all_lookdur{idx} = tmp_look_dur;
  all_labs{idx} = tmp_labs;
  all_distances{idx} = tmp_distances;
end

outs = struct();

outs.labels = vertcat( fcat(), all_labs{is_valid} );
outs.nfix = vertcat( all_nfix{is_valid} );
outs.lookdur = vertcat( all_lookdur{is_valid} );
outs.stim_distances = vertcat( all_distances{is_valid} );

end

function d = get_stimulated_event_distance_from_eyes(roi_file, pos_file, stim_event_start)

eyes_roi = roi_file.m1.rects('eyes_nf');
pos = pos_file.m1;

eye_x = mean( eyes_roi([1, 3]) );
eye_y = mean( eyes_roi([2, 4]) );

stim_x = pos(1, stim_event_start);
stim_y = pos(2, stim_event_start);

d = bfw.distance( eye_x, eye_y, stim_x, stim_y );

end
