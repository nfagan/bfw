function make_plex_raw_time(varargin)

import shared_utils.io.fload;
import shared_utils.sync.cinterp;

ff = @fullfile;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

samples_p = bfw.gid( ff('edf_raw_samples', isd), conf );
unified_p = bfw.gid( ff('unified', isd), conf );
edf_sync_p = bfw.gid( ff('edf_sync', isd), conf );
plex_sync_p = bfw.gid( ff('sync', isd), conf );
plex_time_p = bfw.gid( ff('plex_raw_time', osd), conf );

mats = bfw.require_intermediate_mats( params.files, samples_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  edf_samples_file = fload( mats{i} );
  
  unified_filename = edf_samples_file.unified_filename;
  
  try
    un_file = fload( fullfile(unified_p, unified_filename) );
    edf_sync_file = fload( fullfile(edf_sync_p, unified_filename) );
    plex_sync_file = fload( fullfile(plex_sync_p, unified_filename) );    
  catch err
    warning( '"%s" failed: %s', unified_filename, err.message );
    continue;
  end
  
  output_filename = fullfile( plex_time_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  if ( ~isfield(un_file, 'm1') || ~isfield(un_file.m1, 'plex_sync_id') )
    warning( 'Not implemented for "%s".', unified_filename );
    continue;
  end
  
  if ( ~strcmpi(un_file.m1.plex_sync_id, 'm1') )
    warning( 'Not implemented for "%s".', unified_filename );
    continue;
  end
  
  id_a = un_file.m1.plex_sync_id;
  id_b = char( setdiff({'m1', 'm2'}, id_a) );
  
  mat_sync_a = un_file.(id_a).sync_times(:, 1);
  mat_sync_b = un_file.(id_a).sync_times(:, 2);

  edf_mat_sync_b = un_file.(id_b).plex_sync_times(2:end);
  
  %   now edf_sync_b times are in the same clock-space as mat_sync_a
  edf_mat_sync_ab = shared_utils.sync.cinterp( edf_mat_sync_b, mat_sync_b, mat_sync_a );
  
  m_ind = strcmp( plex_sync_file.sync_key, 'mat' );
  p_ind = strcmp( plex_sync_file.sync_key, 'plex' );
  
  mat_sync_times = plex_sync_file.plex_sync(2:end, m_ind);
  plex_sync_times = plex_sync_file.plex_sync(2:end, p_ind);
  
  fs = intersect( {'m1', 'm2'}, fieldnames(edf_sync_file) );
  
  plex_time_file = struct();
  plex_time_file.unified_filename = unified_filename;
  
  try 
    for j = 1:numel(fs)
      monk_id = fs{j};

      edf_time = edf_samples_file.(monk_id).t;
      edf_sync_times = edf_sync_file.(monk_id).edf_sync_times;

      if ( strcmpi(monk_id, id_a) )
        % If the current `monk_id` is the same as the one used to send sync
        % pulses to plexon, we can directly convert between the
        % `edf_sync_times` and `plex_sync_times`, since they are equivalent.
        edf_plex_time = cinterp( edf_time, edf_sync_times, plex_sync_times );
      else
        % Otherwise, we'll have to first convert the edf_times to matlab
        % time (in terms of `id_a`(s) clock), and *then* to plexon time.
        nans = isnan( edf_mat_sync_ab );
        edf_sync_times(nans) = [];
        edf_mat_sync_ab(nans) = [];

        edf_mat_time = cinterp( edf_time, edf_sync_times, edf_mat_sync_ab );
        edf_plex_time = cinterp( edf_mat_time, mat_sync_times, plex_sync_times );
      end

      plex_time_file.(monk_id) = edf_plex_time;
    end
  catch err
    warning( '"%s" failed: %s', unified_filename, err.message );
    continue;
  end
  
  shared_utils.io.require_dir( plex_time_p );
  shared_utils.io.psave( output_filename, plex_time_file, 'plex_time' );
end

end