function add_plex_time_to_aligned(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

aligned_p = bfw.get_intermediate_directory( 'aligned', conf );
sync_p = bfw.get_intermediate_directory( 'sync', conf );

mats = bfw.require_intermediate_mats( params.files, aligned_p, params.files_containing );

parfor i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  aligned = shared_utils.io.fload( mats{i} );
  
  un_filename = aligned.m1.unified_filename;
  
  sync_file = fullfile( sync_p, un_filename );
  
  if ( ~shared_utils.io.fexists(sync_file) )
    fprintf( '\n Warning: Missing sync file for "%s".', un_filename );
    continue;
  end
  
  if ( isfield(aligned, 'adjustments') && aligned.adjustments.isKey('to_plex_time') )
    if ( ~params.overwrite )
      fprintf( '\n Skipping "%s" because it was already plex-time adjusted.' ...
        , un_filename );
      continue;
    end
  end
  
  sync = shared_utils.io.fload( sync_file );
  
  % assumes units are seconds for both mat and plex
  mat_sync = sync.plex_sync(:, strcmp(sync.sync_key, 'mat'));
  plex_sync = sync.plex_sync(:, strcmp(sync.sync_key, 'plex'));
  
  start_offset_mat = mat_sync(1);
  start_time_plex = plex_sync(1) - start_offset_mat;
  
  if ( aligned.m1.time(1) ~= 0 || aligned.m2.time(1) ~= 0 )
    fprintf( ['\n Warning: Expected first element of `aligned.(x).time` to' ...
      , ' be 0, but was %0.2f'], aligned.m1.time(1) );
    continue;
  end
  
  m1_t = aligned.m1.time;
  mat_t_index = mat_sync >= m1_t(1) & mat_sync <= m1_t(end);
  adjusted_t = zeros( size(m1_t) );
  
  mat_sync = mat_sync(mat_t_index);
  plex_sync = plex_sync(mat_t_index);
  last_bin = plex_sync(1);
  
  for j = 1:numel(mat_sync)-1
    ind_t = m1_t >= mat_sync(j) & m1_t < mat_sync(j+1);
    sum_ind_t = sum( ind_t );
%     plex_sync_interval = (plex_sync(j+1) - plex_sync(j)) / sum_ind_t;
    plex_sync_interval = (mat_sync(j+1) - mat_sync(j)) / sum_ind_t;
    adjusted_t(ind_t) = (0:sum_ind_t-1) .* plex_sync_interval + last_bin;
%     last_bin = last_bin + sum_ind_t * plex_sync_interval;
    last_bin = plex_sync(j+1);
  end

%   adjusted_time_m1 = aligned.m1.time + start_time_plex;
%   adjusted_time_m2 = aligned.m2.time + start_time_plex;
  
  if ( ~isfield(aligned, 'adjustments') )
    aligned.adjustments = containers.Map();
  end
  
  aligned.adjustments('to_plex_time') = params;
  
  fields = fieldnames( aligned );
  
  for j = 1:numel(fields)
    aligned.(fields{j}).plex_time = adjusted_t;
  end
  
  do_save( mats{i}, aligned );
end

end

function do_save( filename, aligned )

save( filename, 'aligned' );

end