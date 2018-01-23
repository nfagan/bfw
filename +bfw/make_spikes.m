function make_spikes()

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

unified_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'spikes' );

shared_utils.io.require_dir( save_p );

un_mats = shared_utils.io.find( unified_p, '.mat' );

parfor i = 1:numel(un_mats)
  
  unified = shared_utils.io.fload( un_mats{i} );
  
  fields = fieldnames( unified );
  firstf = fields{1};
  
  un_filename = unified.(firstf).unified_filename;
  
  un0 = unified.(firstf);
  
  pl2_file = un0.plex_filename;
  pl2_dir_components = un0.plex_directory(1:end-1);
  pl2_dir = fullfile( data_root, pl2_dir_components{:} );
  sorted_subdir = un0.plex_directory{end};
  pl2_fullfile = fullfile( pl2_dir, sorted_subdir, pl2_file );
  
  if ( isempty(pl2_file) )
    fprintf( '\nmake_spikes(): WARNING: No .pl2 file for "%s".', un_filename );
    continue;
  end
  
  unit_map_file = fullfile( pl2_dir, un0.plex_unit_map_filename );
  region_map_file = fullfile( pl2_dir, un0.plex_region_map_filename );
  
  all_maps = bfw.get_plex_region_and_unit_maps( region_map_file, unit_map_file );
  
  unit_map = all_maps.units;
  
  all_units = {};
  stp = 1;
    
  for j = 1:numel(unit_map)
    units_this_channel_set = unit_map(j);
    
    regions = unique( units_this_channel_set.channels );
    units = units_this_channel_set.units;
    
    n_units = numel( units );
    unit_ids = 1:n_units;
    
    C = combvec( regions, unit_ids );
    
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
      
      if ( stp == 1 )
        all_units = current_unit;
      else
        all_units(stp) = current_unit;
      end
      stp = stp + 1;
    end
  end
  
  spikes = struct();
  
  spikes.data = all_units;
  spikes.unified_filename = un0.unified_filename;
  
  do_save( spikes, fullfile(save_p, un0.unified_filename) );
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