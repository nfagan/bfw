function make_lfp(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = bfw.config.load();
data_root = conf.PATHS.data_root;

unified_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'lfp' );

shared_utils.io.require_dir( save_p );

un_mats = bfw.require_intermediate_mats( params.files, unified_p, params.files_containing );

pl2_visited_files = containers.Map();

for i = 1:numel(un_mats)
  fprintf( '\n %d of %d', i, numel(un_mats) );
  
  unified = shared_utils.io.fload( un_mats{i} );
  
  fields = fieldnames( unified );
  firstf = fields{1};
  
  un_filename = unified.(firstf).unified_filename;
  
  full_filename = fullfile( save_p, un_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
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
  
  %   provide a link to the full data, rather than duplicating
  if ( pl2_visited_files.isKey(pl2_fullfile) )
    fprintf( '\n Using cached data for "%s".', pl2_fullfile );
    lfp = struct();
    lfp.is_link = true;
    lfp.data_file = pl2_visited_files( pl2_fullfile );
    do_save( lfp, fullfile(save_p, un_filename) );
    continue;
  end
  
  pl2_visited_files(pl2_fullfile) = un_filename;
  
  unit_map_file = fullfile( pl2_dir, un0.plex_unit_map_filename );
  region_map_file = fullfile( pl2_dir, un0.plex_region_map_filename );
  
  all_maps = bfw.get_plex_region_and_unit_maps( region_map_file, unit_map_file );
  
  region_map = all_maps.regions;
  
  stp = 1;
  
  need_preallocate = true;
  
  total_number_of_channels = sum( arrayfun(@(x) numel(x.channels), region_map) );
  identifiers = cell( total_number_of_channels, 2 );
  rejects = false( total_number_of_channels, 1 );
  
  key_cols = containers.Map();
  key_cols('channel') = 1;
  key_cols('region') = 2;
    
  for j = 1:numel(region_map)
    
    region_name = region_map(j).name;
    channels = region_map(j).channels;
    
    for k = 1:numel(channels)
      channel_str = channel_n_to_str( 'FP', channels(k) );
      
      ad = PL2Ad( pl2_fullfile, channel_str );
      samples = ad.Values;
      n_samples = numel( samples );
      sample_rate = ad.ADFreq;
      
      if ( n_samples ~= 0 )
        if ( need_preallocate )
          lfp_mat = nan( total_number_of_channels, n_samples );
          need_preallocate = false;
        end

        lfp_mat( stp, : ) = samples;

        identifiers{stp, 1} = channel_str;
        identifiers{stp, 2} = region_name;
      else
        fprintf( '\n WARNING: No data for "%s", "%s".', pl2_file, channel_str );
        rejects(stp) = true;
      end

      stp = stp + 1;
    end
  end
  
  if ( all(rejects) ), continue; end
  
  identifiers(rejects, :) = [];
  lfp_mat(rejects, :) = [];
  
  lfp = struct();
  
  lfp.is_link = false;
  lfp.data = lfp_mat;
  lfp.unified_filename = un_filename;
  lfp.key = identifiers;
  lfp.key_column_map = key_cols;
  lfp.sample_rate = sample_rate;
  lfp.id_times = (0:size(lfp_mat, 2)-1) * (1/sample_rate);
  
  do_save( lfp, full_filename );
end

end

function do_save( var, filename )

save( filename, 'var' );

end

function str = channel_n_to_str( prefix, n )

if ( n < 10 )
  str = sprintf( '%s0%d', prefix, n );
else
  str = sprintf( '%s%d', prefix, n );
end

end