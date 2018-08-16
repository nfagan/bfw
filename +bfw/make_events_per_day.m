function make_events_per_day(varargin)

import shared_utils.io.fload;
ff = @fullfile;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

event_p = bfw.gid( ff('events', isd), conf );
unified_p = bfw.gid( ff('unified', isd), conf );

event_files = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

session_map = containers.Map();

for i = 1:numel(event_files)
  events = fload( event_files{i} );
  un_filename = events.unified_filename;
  
  unified = fload( fullfile(unified_p, un_filename) );
  
  if ( ~events.adjustments.isKey('to_plex_time') )
    fprintf( '\n Events have not yet been converted to plexon time for "%s".', un_filename );
    continue;
  end
  
  session_name = unified.m1.mat_directory_name;
  
  if ( ~session_map.isKey(session_name) )
    session_map(session_name) = events;
  else
    current = session_map(session_name);
    session_map(session_name) = [ current; events ];
  end
end

session_names = session_map.keys();

for i = 1:numel(session_names)
  fprintf( '\n %d of %d', i, numel(session_names) );
  events = session_map(session_names{i});
  one_session( events, params );
end

end

function one_session( events, params )

import shared_utils.io.fload;
ff = @fullfile;

isd = params.input_subdir;
osd = params.output_subdir;

if ( numel(events) == 0 ), return; end

unified_p = bfw.gid( ff('unified', isd), params.config );
evt_save_p = bfw.gid( ff('events_per_day', osd), params.config );

allow_overwrite = params.overwrite;

event_info = Container();

event_info_keys = { 'times', 'durations', 'lengths', 'ids', 'looked_first' };
event_info_vals = 1:numel(event_info_keys);
event_info_key = containers.Map( event_info_keys, event_info_vals );

for i = 1:numel(events)
  fprintf( '\n\t %d of %d', i, numel(events) );
  
  evt = events(i);
  
  rois = evt.roi_key.keys();
  monks = evt.monk_key.keys();
  
  unified_filename = evt.unified_filename;
  
  unified = fload( fullfile(unified_p, unified_filename) );
  
  mat_directory_name = unified.m1.mat_directory_name;
  
  for j = 1:numel(rois)
    roi = rois{j};
    row = evt.roi_key(roi);
    
    for k = 1:numel(monks)
      monk = monks{k};
      col = evt.monk_key(monk);
      
      c_evt_times = evt.times{row, col};
      c_durations = evt.durations{row, col};
      c_lengths = evt.lengths{row, col};
      c_ids = double( evt.identifiers{row, col} );
      c_looked_first = nan( size(c_ids) );
      
      if ( strcmp(monk, 'mutual') )
        c_looked_first = evt.looked_first_indices{row, 1};
      end
      
      look_orders = cell( numel(c_looked_first), 1 );
      
      for h = 1:numel(c_looked_first)
        look_order = c_looked_first(h);
        
        if ( isnan(look_order) )
          lo = 'NaN';
        elseif ( look_order == 0 )
          lo = 'simultaneous';
        elseif ( look_order == 1 )
          lo = 'm1';
        else
          assert( look_order == 2, 'Unrecognized look order %d.', look_order );
          lo = 'm2';
        end        
        
        look_orders{h} = sprintf( 'look_order__%s', lo );
      end
      
      labs = SparseLabels.create( ...
          'unified_filename', unified_filename ...
        , 'session_name', mat_directory_name ...
        , 'looks_to', roi ...
        , 'looks_by', monk ...
        , 'look_order', look_orders ...
      );
    
      data = [ c_evt_times(:), c_durations(:), c_lengths(:), c_ids(:), c_looked_first(:) ];
    
      event_info = append( event_info, Container(data, labs) );
    end
  end
end

shared_utils.io.require_dir( evt_save_p );

for i = 1:numel(events)
  evt = events(i);
  
  unified_filename = evt.unified_filename;
  
  full_save_filename = fullfile( evt_save_p, unified_filename );
  
  if ( bfw.conditional_skip_file(full_save_filename, allow_overwrite) )
    continue;
  end
  
  all_event_info = struct();
  
  if ( i == 1 )
    all_event_info.event_info = event_info;
    all_event_info.event_info_key = event_info_key;
    all_event_info.unified_filename = unified_filename;
    all_event_info.is_link = false;
  else
    all_event_info.is_link = true;
    all_event_info.data_file = events(1).unified_filename;
    all_event_info.unified_filename = unified_filename;
  end
  
  save( full_save_filename, 'all_event_info' );
end

end