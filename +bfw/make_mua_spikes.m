function make_mua_spikes(varargin)

conf = bfw.config.load();
data_p = conf.PATHS.data_root;

defaults = bfw.get_common_make_defaults();
defaults = bfw.get_common_lfp_defaults( defaults );
defaults.std_threshold = 3;
defaults.f1 = 700;
defaults.f2 = 1800;
defaults.sample_rate = 40e3;

params = bfw.parsestruct( defaults, varargin );

input_p = bfw.get_intermediate_directory( 'lfp' );
un_p = bfw.get_intermediate_directory( 'unified' );
output_p = bfw.get_intermediate_directory( 'mua_spikes' );

mats = bfw.require_intermediate_mats( params.files, input_p, params.files_containing );

for i = 1:numel(mats)
  bfw.progress( i, numel(mats), mfilename );
  
  lfp_file = shared_utils.io.fload( mats{i} );
  
  if ( lfp_file.is_link )
    continue;
  end
  
  un_filename = lfp_file.unified_filename;
  
  un_file = shared_utils.io.fload( fullfile(un_p, un_filename) );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  pl2_file = fullfile( data_p, un_file.m1.plex_directory{:}, un_file.m1.plex_filename );
  
  chans = lfp_file.key(:, lfp_file.key_column_map('channel'));
  chans = cellfun( @(x) strrep(x, 'FP', 'WB'), chans, 'un', false );
  
  for j = 1:numel(chans)
    fprintf( '\n\t %d of %d', j, numel(chans) );
    
    wb = PL2Ad( pl2_file, chans{j} );
    
    data = wb.Values;
    data = bfw.zpfilter( data, params.f1, params.f2, wb.ADFreq, params.filter_order );
    data = bfw.get_mua_data( data(:)', params.std_threshold );
    
    if ( j == 1 )
      id_times = (0:numel(wb.Values)-1) .* (1/wb.ADFreq);
    end
    
    unit = struct();
    
    unit.times = id_times( data );
    unit.channel = str2double( chans{j}(3:4) );
    unit.channel_str = chans{j};
    unit.region = lfp_file.key(j, lfp_file.key_column_map('region'));
    
    if ( j == 1 )
      all_units = unit;
    else
      all_units(j) = unit;
    end
  end
  
  shared_utils.io.require_dir( output_p );
  
  mua_struct = struct();
  
  mua_struct.is_link = false;
  mua_struct.data = all_units;
  mua_struct.unified_filename = un_filename;
  
  save( output_filename, 'mua_struct' );  
end

end