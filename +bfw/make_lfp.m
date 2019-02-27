function make_lfp(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();
defaults.save_flags = {};

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
data_root = conf.PATHS.data_root;
isd = params.input_subdir;
osd = params.output_subdir;

save_flags = cellstr( params.save_flags );

unified_p = bfw.gid( ff('unified', isd), conf );
save_p = bfw.gid( ff('lfp', osd), conf );

shared_utils.io.require_dir( save_p );

un_mats = bfw.require_intermediate_mats( params.files, unified_p, params.files_containing );

pl2_visited_files = containers.Map();
channel_map = bfw.get_plex_meta_channel_map( conf );

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
  
  all_sessions = channel_map( 'session' );
  all_regions = channel_map( 'region' );
  all_channels = channel_map( 'channels' );
  
  session_name = un0.mat_directory_name;
  session_ind = strcmpi( all_sessions, session_name );
  
  if ( nnz(session_ind) == 0 )
    warning( 'Missing region + channel specifiers for "%s".', un_filename );
    continue;
  end
  
  regions = all_regions(session_ind);
  channels = all_channels(session_ind);
  
  pl2_visited_files(pl2_fullfile) = un_filename;  
  
  stp = 1;
  
  need_preallocate = true;
  
  total_number_of_channels = sum( cellfun(@numel, channels) );
  identifiers = cell( total_number_of_channels, 2 );
  rejects = false( total_number_of_channels, 1 );
  
  key_cols = containers.Map();
  key_cols('channel') = 1;
  key_cols('region') = 2;
    
  for j = 1:numel(regions)
    
    region_name = regions{j};
    chans = channels{j};
    
    for k = 1:numel(chans)
      channel_str = channel_n_to_str( 'FP', chans(k) );
      
      ad = PL2Ad( pl2_fullfile, channel_str );
      samples = ad.Values;
      n_samples = numel( samples );
      sample_rate = ad.ADFreq;
      
      if ( n_samples ~= 0 )
        if ( need_preallocate )
          lfp_mat = nan( total_number_of_channels, n_samples );
          need_preallocate = false;
        end

        lfp_mat(stp, :) = samples;

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
  
  do_save( lfp, full_filename, save_flags{:} );
end

end

function do_save(var, filename, varargin)

save( filename, 'var', varargin{:} );

end

function str = channel_n_to_str( prefix, n )

if ( n < 10 )
  str = sprintf( '%s0%d', prefix, n );
else
  str = sprintf( '%s%d', prefix, n );
end

end