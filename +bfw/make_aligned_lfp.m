function make_aligned_lfp(varargin)

import shared_utils.io.fload;
ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.window_size = 150;
defaults.look_back = -500;
defaults.look_ahead = 500;
defaults.sample_rate = 1e3;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

lfp_p = bfw.gid( ff('lfp', isd), conf );
event_p = bfw.gid( ff('events_per_day', isd), conf );
output_p = bfw.gid( ff('event_aligned_lfp', osd), conf );

event_files = bfw.require_intermediate_mats( params.files, event_p, params.files_containing );

look_ahead = params.look_ahead;
look_back = params.look_back;
window_size = params.window_size;

parfor i = 1:numel(event_files)
  
  events = fload( event_files{i} );
  un_filename = events.unified_filename;
  
  output_file = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_file, params.overwrite) )
    continue; 
  end
  
  shared_utils.io.require_dir( output_p );
  
  lfp_file = fullfile( lfp_p, un_filename );
  
  if ( ~shared_utils.io.fexists(lfp_file) )
    fprintf( '\n LFP file for "%s" does not exist.', un_filename );
    continue;
  end
  
  if ( events.is_link )
    lfp_struct = struct();
    lfp_struct.is_link = true;
    lfp_struct.data_file = events.data_file;
    lfp_struct.unified_filename = un_filename;
    do_save( output_file, lfp_struct );
    continue;
  end
  
  lfp = fload( lfp_file );
  
  if ( lfp.is_link )
    lfp = fload( fullfile(lfp_p, lfp.data_file) );
  end
  
  event_info = events.event_info;
  event_times = event_info.data(:, events.event_info_key('times'));
  
  if ( lfp.sample_rate ~= params.sample_rate )
    fprintf( '\n Warning: Incorrect sample rate for "%s".', un_filename );
    continue;
  end
  
  if ( lfp.sample_rate ~= 1e3 )
    fprintf( '\n Warning: Expected sample rate to be 1000; instead was %d', lfp.sample_rate );
    continue;
  end
  
  id_times = lfp.id_times;
  id_time_indices = nan( numel(event_times), 1 );
  
  for j = 1:numel(event_times)
    current_time = event_times(j);
    [~, index] = histc( current_time, id_times );
    out_of_bounds_msg = ['The id_times do not properly correspond to the' ...
      , ' inputted events for "%s".'];
    is_in_bounds = index ~= 0;
    assert( is_in_bounds, out_of_bounds_msg, un_filename );
    check = abs( current_time - id_times(index) ) < abs( current_time - id_times(index+1) );
    if ( ~check ), index = index + 1; end;
    id_time_indices(j) = index;
  end
  
  n_lfp_channels = size( lfp.data, 1 );
  
  total_n_samples = look_ahead - look_back + window_size;
  
  all_lfp_data = nan( numel(event_times) * n_lfp_channels, total_n_samples );
  
  all_indices = bfw.allcombn( {1:numel(event_times), 1:n_lfp_channels} );
  
  addtl_lfp_labels = cell( size(all_indices, 1), size(lfp.key, 2) );
  
  oob = false( size(all_indices, 1), 1 );
  
  for j = 1:size(all_indices, 1)
    event_time_index = all_indices{j, 1};
    channel_index = all_indices{j, 2};
    id_time_index = id_time_indices(event_time_index);
    
    start = floor( id_time_index + look_back - (window_size/2) );
    stop = floor( id_time_index + look_ahead + window_size - (window_size/2) );
    
    if ( start < 1 || stop > numel(id_times) )
      oob(j) = true;
      continue;
    end
    
    all_lfp_data(j, :) = lfp.data(channel_index, start:stop-1);
    
    addtl_lfp_labels(j, :) = lfp.key(channel_index, :);
  end
  
  all_event_indices = all_indices(:, 1);
  all_event_indices = [ all_event_indices{:} ];
  
  lfp_cont = set_data( event_info(all_event_indices), all_lfp_data );
  
  column_keys = lfp.key_column_map.keys();
  
  for j = 1:numel(column_keys)
    category_name = column_keys{j};
    col = lfp.key_column_map(category_name);
    lfp_cont = lfp_cont.require_fields( category_name );
    lfp_cont(category_name) = addtl_lfp_labels(:, col);
  end
  
  lfp_struct = struct();
  lfp_struct.lfp = lfp_cont;
  lfp_struct.event_info = event_info;
  lfp_struct.out_of_bounds = oob;
  lfp_struct.unified_filename = un_filename;
  lfp_struct.is_link = false;
  lfp_struct.params = params;
  
  do_save( output_file, lfp_struct );
end  
  
end

function do_save( filename, variable )
save( filename, 'variable' );
end