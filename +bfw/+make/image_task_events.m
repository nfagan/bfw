function events_file = image_task_events(files)

bfw.validatefiles( files, {'unified', 'sync'} );

unified_file = shared_utils.general.get( files, 'unified' );
sync_file = shared_utils.general.get( files, 'sync' );

if ( ~bfw.is_image_task(unified_file.m1.task_type) )
  error( 'Function "%s" is not defined for non-image task.', mfilename );
end

expected_events = { 'image_onset', 'stim_deactivated', 'image_offset', 'inter_image_interval_reward_onset' };

monk_fields = fieldnames( unified_file );

events_file = struct();
events_file.unified_filename = bfw.try_get_unified_filename( unified_file );
events_file.event_key = expected_events;

for i = 1:numel(monk_fields)
  monk_field = monk_fields{i};
  trial_data = unified_file.(monk_field).trial_data;
  
  events = get_events( trial_data, expected_events );
  events = events_to_plexon( events, sync_file );
  
  events_file.(monk_field).events = events;
end

end

function events = events_to_plexon(events, sync_file)

import shared_utils.sync.cinterp;

mat_sync = bfw.extract_sync_times( sync_file, 'mat' );
plex_sync = bfw.extract_sync_times( sync_file, 'plex' );

for i = 1:size(events, 2)
  events(:, i) = cinterp( events(:, i), mat_sync, plex_sync );
end

end

function events = get_events(trial_data, expected_events)

events = nan( numel(trial_data), numel(expected_events) );

for i = 1:numel(trial_data)
  evts = trial_data(i).events;
  event_fields = fieldnames( evts );
  
  for j = 1:numel(event_fields)
    [~, loc] = ismember( event_fields{j}, expected_events );
    
    if ( loc == 0 )
      continue;
    end
    
    events(i, loc) = evts.(event_fields{j});
  end
end

end