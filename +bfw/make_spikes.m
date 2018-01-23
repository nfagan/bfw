function make_spikes()

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

unified_p = bfw.get_intermediate_directory( 'unified' );

un_mats = shared_utils.io.find( unified_p, '.mat' );

for i = 1:numel(un_mats)
  
  unified = shared_utils.io.fload( un_mats{i} );
  
  fields = fieldnames( unified );
  firstf = fields{1};
  
  un_filename = unified.(firstf).unified_filename;
  
  un0 = unified.(firstf);
  
  pl2_file = un0.plex_filename;
  pl2_dir = fullfile( data_root, un0.plex_directory{:} );
  pl2_fullfile = fullfile( pl2_dir, pl2_file );
  
  if ( isempty(pl2_file) )
    fprintf( '\nmake_spikes(): WARNING: No .pl2 file for "%s".', un_filename );
    continue;
  end
  
  channels = un0.plex_channel_map;
  unit_map = un0.plex_unit_map;
  
  for j = 1:numel(unit_map)
    units_this_channel_set = unit_map(j);
    
    channels = unique( units_this_channel_set.channels );
    units = units_this_channel_set.units;
    
    n_units = numel( units );
    unit_ids = 1:n_units;
    
    C = combvec( channels, unit_ids );
    
    for k = 1:size(C, 2)
      
      channel = C(1, k);
      unit_id_index = C(2, k);
      unit_id = units(unit_id_index).number;
      channel_str = channel_n_to_str( channel );
      spikes = PL2Ts( pl2_fullfile, channel_str, unit_id );
    end
  end
end

end

function str = channel_n_to_str( n )

if ( n < 10 )
  str = sprintf( 'SPK0%d', n );
else
  str = sprintf( 'SPK%d', n );
end

end