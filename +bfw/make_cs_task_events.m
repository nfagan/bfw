function make_cs_task_events(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

mid = params.cs_monk_id;
isd = params.input_subdir;
osd = params.output_subdir;

unified_p = bfw.get_intermediate_directory( fullfile('cs_unified', mid, isd), conf );
sync_p = bfw.get_intermediate_directory( fullfile('cs_sync', mid, isd), conf );
save_p = bfw.get_intermediate_directory( fullfile('cs_task_events', mid, osd), conf );

mats = bfw.require_intermediate_mats( params.files, unified_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  cs_unified_file = shared_utils.io.fload( mats{i} );
  
  cs_unified_filename = cs_unified_file.cs_unified_filename;
  output_filename = fullfile( save_p, cs_unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  cs_sync_filename = fullfile( sync_p, cs_unified_filename );
  
  if ( ~shared_utils.io.fexists(cs_sync_filename) )
    warning( 'File "%s" is missing a sync file.', cs_unified_filename );
    continue;
  end
  
  sync_file = shared_utils.io.fload( cs_sync_filename );
  
  mat_time = sync_file.plex_sync(:, strcmp(sync_file.sync_key, 'mat'));
  plex_time = sync_file.plex_sync(:, strcmp(sync_file.sync_key, 'plex'));
  
  events = { cs_unified_file.data.DATA(:).events };
  [evts, evt_names] = events_struct2mat( events );
  evts = events2plex( evts, mat_time, plex_time );
  
  events_file = struct();
  events_file.event_times = evts;
  events_file.event_key = evt_names;
  events_file.cs_unified_filename = sync_file.cs_unified_filename;
  
  shared_utils.io.require_dir( save_p );
  save( output_filename, 'events_file' );  
end

end

function evts = events2plex(events, mat_sync, plex_sync)

n_events = size( events, 2 );
evts = nan( size(events) );

for i = 1:n_events
  evts(:, i) = bfw.clock_a_to_b( events(:, i), mat_sync(:), plex_sync(:) );
end

end

function [evts, fs] = events_struct2mat(events)

fs = cellfun( @fieldnames, events, 'un', 0 );
all_n_fields = cellfun( @numel, fs );
n_trials = numel( events );

[n_fields, I] = max( all_n_fields );

fs = fs{I};

evts = nan( n_trials, n_fields );

for i = 1:n_trials
  trial = events{i};
  for j = 1:n_fields
    
    fieldname = fs{j};
    if ( ~isfield(trial, fieldname) ), continue; end
    evts(i, j) = trial.(fieldname);
  end
end

end
