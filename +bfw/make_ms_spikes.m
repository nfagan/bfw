function make_ms_spikes(varargin)

import shared_utils.char.containsi;
ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.sample_rate = 40e3;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

data_root = conf.PATHS.data_root;

unified_p = bfw.gid( ff('unified', isd), conf );
save_p = bfw.gid( ff('spikes', osd), conf );

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
  unit_n_ind = cellfun( @(x) strcmpi(x, 'unit'), header );
  rating_ind = cellfun( @(x) containsi(x, 'rating'), header );
  day_ind = cellfun( @(x) containsi(x, 'day'), header );
  unit_id_ind = cellfun( @(x) strcmpi(x, 'id'), header );
  
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
%   ms_unit_ids = cellfun( @(x) num2str(x), ms_channel_map(2:end, unit_id_ind) );
  ms_unit_ids = cellfun( @(x) num2str(x), ms_channel_map(2:end, unit_id_ind), 'un', false );
  ms_unit_ratings = cellfun( @(x) x, ms_channel_map(2:end, rating_ind) );
  
  c_day_ind = strcmp( ms_day_ids, un0.mat_directory_name );
  
  if ( ~any(c_day_ind) )
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
  
  pl2_file = un0.plex_filename;
  
  if ( isempty(pl2_file) )
    fprintf( '\n No .pl2 file defined for "%s".', un_filename );
    continue;
  end
  
  pl2_dir_components = un0.plex_directory(1:end-1);
  pl2_dir = fullfile( data_root, pl2_dir_components{:} );
  sorted_subdir = un0.plex_directory{end};
  pl2_fullfile = fullfile( pl2_dir, sorted_subdir, pl2_file );
  
  region_map_file = fullfile( pl2_dir, un0.plex_region_map_filename );
  
  region_map = bfw.unify_plex_region_map( bfw.jsondecode(region_map_file) );
  
  all_units = {};
  stp = 1;
  
  for j = 1:numel(firings_file_map)
    fprintf( '\n\t %d of %d', j, numel(firings_file_map) );
    
    %   pre-2017a json parser returns cell array of struct
    if ( iscell(firings_file_map) )
      current_file_map = firings_file_map{j};
    else
      current_file_map = firings_file_map(j);
    end
    
    firings_filename = current_file_map.file_name;
    firings_channels = bfw.parse_json_channel_numbers( current_file_map.channels );
    firings_channels = sort( firings_channels );
    
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
    
    complete_ms_index = false( size(spike_times) );
    
    for k = 1:numel(firings_channels)
      fprintf( '\n\t\t %d of %d', k, numel(firings_channels) );
      
      xls_channel_id = firings_channels(k);
      xls_channel_ind = ms_channel_map_ids == xls_channel_id;
      xls_channel_ind = xls_channel_ind & c_day_ind;
      
      if ( ~any(xls_channel_ind) )
        fprintf( '\n Warning: No channels matched %d for "%s" in the excel file.', xls_channel_id, un_filename );
        continue;
      end
      
      region_name = get_region_name_from_channel_n( region_map, xls_channel_id );
      
      if ( isempty(region_name) )
        fprintf( '\n Warning: No region was defined for channel %d in "%s".', xls_channel_id, un_filename );
        continue;
      end
      
      ms_channel_id = xls_channel_id - firings_channels(1) + 1;
      ms_channel_id_ind = channel_ids == ms_channel_id;
      ms_unit_ids_from1 = unit_ids( ms_channel_id_ind );
      %   ms unit ids increment from 1 -> N such that each unit id is unique
      %   across channels. our unit ids restart from 1 at each channel.
      ms_unit_ids_from1 = ms_unit_ids_from1 - min(ms_unit_ids_from1) + 1;
      
      unit_ids_this_channel = ms_unit_ids( xls_channel_ind );
      unit_ns_this_channel = ms_unit_numbers( xls_channel_ind );
      unit_ratings_this_channel = ms_unit_ratings( xls_channel_ind );
      
      if ( numel(unique(unit_ns_this_channel)) ~= numel(unit_ns_this_channel) )
        fprintf( '\n Warning: Unit numbers must be unique for each channel. Skipping "%s, %d".' ...
          , un_filename, xls_channel_id );
        continue;
      end
      
      complete_ms_index(:) = false;
      
      for h = 1:numel(unit_ns_this_channel)
        fprintf( '\n\t\t\t %d of %d', h, numel(unit_ns_this_channel) );
        
        unit_n_this_channel = unit_ns_this_channel(h);
        ms_unit_id_ind = ms_unit_ids_from1 == unit_n_this_channel;
        
        complete_ms_index( ms_channel_id_ind ) = ms_unit_id_ind;
        
        if ( ~any(ms_unit_id_ind) )
%           fprintf( '\n Warning: No units matched id %d for "%s".', unit_n_this_channel, un_filename );
          error( 'No units matched id %d for channel %d in "%s".' ...
            , unit_n_this_channel, xls_channel_id, un_filename );
%           continue;
        end
        
        current_unit = struct();
        
        current_unit.times = spike_times(complete_ms_index) / params.sample_rate;
        current_unit.channel = xls_channel_id;
        current_unit.channel_str = channel_n_to_str( xls_channel_id );
        current_unit.rating = unit_ratings_this_channel(h);
        current_unit.uuid = unit_ids_this_channel(h);
        current_unit.region = region_name;
        
        if ( stp == 1 )
          all_units = current_unit;
        else
          all_units(stp) = current_unit;
        end
        stp = stp + 1;
      end
    end
  end
  
  ms_visited_files(ms_firings_fullfile) = un_filename;
    
  spikes = struct();
  
  spikes.is_link = false;
  spikes.data = all_units;
  spikes.unified_filename = un0.unified_filename;
  
  do_save( spikes, full_filename );
end

end

function out = get_region_name_from_channel_n( region_map, n )

for i = 1:numel(region_map)
  chans = region_map(i).channels;
  if ( any(chans == n) )
    out = region_map(i).name;
    return;
  end
end

out = [];

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