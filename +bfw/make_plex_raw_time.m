function results = make_plex_raw_time(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'edf_raw_samples', 'edf_sync', 'unified', 'sync' };
output = 'plex_raw_time';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.func_name = mfilename;

results = loop_runner.run( @make_plex_raw_time_main, params );

end

function plex_time_file = make_plex_raw_time_main(files, unified_filename, params)

import shared_utils.sync.cinterp;

un_file = shared_utils.general.get( files, 'unified' );
edf_samples_file = shared_utils.general.get( files, 'edf_raw_samples' );
edf_sync_file = shared_utils.general.get( files, 'edf_sync' );
plex_sync_file = shared_utils.general.get( files, 'sync' );
  
% skip if no 'm1' field is present, or if no 'plex_sync_id' field is
% present.
if ( ~isfield(un_file, 'm1') || ~isfield(un_file.m1, 'plex_sync_id') )
  error( '"%s": Missing ''plex_sync_id'' field.', unified_filename );
end

id_a = un_file.m1.plex_sync_id;
id_b = char( setdiff({'m1', 'm2'}, id_a) );

has_multiple_fields = isfield( un_file, id_b );

if ( has_multiple_fields )
  mat_sync_a = un_file.(id_a).sync_times(:, 1);
  mat_sync_b = un_file.(id_a).sync_times(:, 2);

  edf_mat_sync_b = un_file.(id_b).plex_sync_times(2:end);

  %   now edf_sync_b times are in the same clock-space as mat_sync_a
  edf_mat_sync_ab = cinterp( edf_mat_sync_b, mat_sync_b, mat_sync_a );
end

m_ind = strcmp( plex_sync_file.sync_key, 'mat' );
p_ind = strcmp( plex_sync_file.sync_key, 'plex' );

mat_sync_times = plex_sync_file.plex_sync(2:end, m_ind);
plex_sync_times = plex_sync_file.plex_sync(2:end, p_ind);

fs = intersect( {'m1', 'm2'}, fieldnames(edf_sync_file) );

plex_time_file = struct();
plex_time_file.unified_filename = unified_filename;
plex_time_file.sync_id = id_a;

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
    assert( has_multiple_fields, ['Only a single field was present in' ...
      , ' unified data, but ''plex_sync_id'' does not match that field.'] );

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

end