function make_ms_spikes(varargin)

import shared_utils.char.containsi;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

unified_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'spikes' );

shared_utils.io.require_dir( save_p );

un_mats = bfw.require_intermediate_mats( params.files, unified_p, params.files_containing );

ms_visited_files = containers.Map();

for i = 1:numel(un_mats)
  fprintf( '\n %d of %d', i, numel(un_mats) );
  
  unified = shared_utils.io.fload( un_mats{i} );
  
  fields = fieldnames( unified );
  firstf = fields{1};
  
  un_filename = unified.(firstf).unified_filename;
  
  un0 = unified.(firstf);
  
  full_filename = fullfile( save_p, un0.unified_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  ms_file_map = un0.ms_firings_file_map_filename;
  ms_file_map_dir_components = un0.ms_firings_file_map_directory;
  
  ms_firings_fullfile = fullfile( data_root, ms_file_map_dir_components{:}, ms_file_map );
  
  if ( ~shared_utils.io.fexists(ms_firings_fullfile) )
    fprintf( '\n Warning: ms file map "%s" does not exist. Skipping "%s"' ...
      , ms_firings_fullfile, un_filename );
    continue;
  end
  
  firings_file_map = bfw.jsondecode( ms_firings_fullfile );
  ms_channel_map_file = fullfile( data_root, un0.ms_firings_directory{:} ...
    , un0.ms_firings_channel_map_filename );
  
  if ( ~shared_utils.io.fexists(ms_channel_map_file) )
    fprintf( '\n Warning: channel map excel file "%s" does not exist.' ...
      , ms_channel_map_file );
    continue;
  end
  
  [~, ~, ms_channel_map] = xlsread( ms_channel_map_file, 'Sheet1' );
  
  header = ms_channel_map(1, :);
  
  channel_ind = cellfun( @(x) containsi(x, 'channel'), header );
  unit_n_ind = cellfun( @(x) containsi(x, 'unit'), header );
  rating_ind = cellfun( @(x) containsi(x, 'rating'), header );
  day_ind = cellfun( @(x) containsi(x, 'day'), header );
  unit_id_ind = cellfun( @(x) containsi(x, 'id'), header );
  
  assert__any_header_indices( channel_ind, unit_n_ind, unit_id_ind, rating_ind, day_ind );
  
  %   get rid of header
  ms_channel_map_ids = cellfun( @(x) x, ms_channel_map(2:end, channel_ind) );
  
  ms_day_ids = cell( size(ms_channel_map_ids) );
  for j = 1:numel(ms_day_ids)
    day_id = ms_channel_map{j+1, day_ind};
    if ( ~ischar(day_id) )
      day_id = num2str( day_id );
    end
    %   excel truncates leading zeros; add them back in if necessary.
    if ( numel(day_id) ~= 8 )
      assert( numel(day_id) == 7, ['Expected a date format like this:' ...
        , ' 01042018, or this: 1042018, but got this: %s'], day_id );
      day_id = [ '0', day_id ];
    end
    ms_day_ids{j} = day_id;
  end
  
  ms_unit_numbers = cellfun( @(x) x, ms_channel_map(2:end, unit_n_ind) );
  ms_unit_ids = cellfun( @(x) x, ms_channel_map(2:end, unit_id_ind) );
  
  matching_day_ind = strcmp( ms_day_ids, un0.mat_directory_name );
  
  if ( ~any(matching_day_ind) )
    fprintf( '\n Warning: No mountain sort units were defined for "%s"', un0.mat_directory_name );
    continue;
  end
  
   %   provide a link to the full data, rather than duplicating
  if ( ms_visited_files.isKey(ms_firings_fullfile) )
    fprintf( '\n Using cached data for "%s".', un_filename );
    
    spikes = struct();
    
    spikes.is_link = true;
    spikes.data_file = ms_visited_files( ms_firings_fullfile );
    
    do_save( spikes, fullfile(save_p, un_filename) );
    continue;
  end
  
  pl2_dir_components = un0.plex_directory(1:end-1);
  pl2_dir = fullfile( data_root, pl2_dir_components{:} );
  
  unit_map_file = fullfile( pl2_dir, un0.plex_unit_map_filename );
  region_map_file = fullfile( pl2_dir, un0.plex_region_map_filename );
  
  all_maps = bfw.get_plex_region_and_unit_maps( region_map_file, unit_map_file );
  
  unit_map = all_maps.units;
  region_map = all_maps.regions;
  
  for j = 1:numel(firings_file_map)
    
    %   pre-2017a json parser returns cell array of struct
    if ( iscell(firings_file_map) )
      current_file_map = firings_file_map{j};
    else
      current_file_map = firings_file_map(j);
    end
    
    firings_filename = current_file_map.file_name;
    firings_channels = bfw.parse_json_channel_numbers( current_file_map.channels );
    
    firings_full_file = fullfile( data_root, un0.ms_firings_directory{:}, firings_filename );
    
    if ( ~shared_utils.io.fexists(firings_full_file) )
      fprintf( '\n Warning: missing firings_out file "%s" for "%s".' ...
        , firings_filename, un_filename );
      continue;
    end
    
    spike_data = readmda( firings_full_file );
    
    channel_ids = spike_data(1, :);
    spike_times = spike_data(2, :);
    unit_ids = spike_data(3, :);

    current_unit.times = spikes;
    current_unit.channel = channel;
    current_unit.channel_str = channel_str;
    current_unit.region = units_this_channel_set.region;
  end
  
  ms_visited_files(ms_firings_fullfile) = un_filename;
  
  all_units = {};
  stp = 1;
    
  for j = 1:numel(unit_map)
    units_this_channel_set = unit_map(j);
    
    regions = unique( units_this_channel_set.channels );
    units = units_this_channel_set.units;
    
    n_units = numel( units );
    unit_ids = 1:n_units;
    
    C = combvec( regions(:)', unit_ids );
    
    for k = 1:size(C, 2)
      
      channel = C(1, k);
      unit_id_index = C(2, k);
      current_unit = units(unit_id_index);
      %   non-native json parser (pre r2017a) loads array of structs as
      %   cell arrays
      if ( iscell(current_unit) ), current_unit = current_unit{1}; end
      
      unit_id = current_unit.number;
      channel_str = channel_n_to_str( channel );
      spikes = PL2Ts( pl2_fullfile, channel_str, unit_id );
      
      current_unit.times = spikes;
      current_unit.channel = channel;
      current_unit.channel_str = channel_str;
      current_unit.region = units_this_channel_set.region;
      
      if ( stp == 1 )
        all_units = current_unit;
      else
        all_units(stp) = current_unit;
      end
      stp = stp + 1;
    end
  end
  
  spikes = struct();
  
  spikes.is_link = false;
  spikes.data = all_units;
  spikes.unified_filename = un0.unified_filename;
  
  do_save( spikes, full_filename );
end

end

function assert__any_header_indices( varargin )

for i = 1:numel(varargin)
  if ( sum(varargin{i}) ~= 1 )
    error( 'Excel channel map file is missing a required header column.' );
  end
end

end

function do_save( var, filename )

save( filename, 'var' );

end

function str = channel_n_to_str( n )

if ( n < 10 )
  str = sprintf( 'SPK0%d', n );
else
  str = sprintf( 'SPK%d', n );
end

end