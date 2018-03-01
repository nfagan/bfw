function make_edf_fixations(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

edf_p = bfw.get_intermediate_directory( 'edf' );
output_p = bfw.get_intermediate_directory( 'fixations' );
unified_p = bfw.get_intermediate_directory( 'unified' );
aligned_p = bfw.get_intermediate_directory( 'aligned' );

edfs = bfw.require_intermediate_mats( params.files, edf_p, params.files_containing );

parfor i = 1:numel(edfs)
  fprintf( '\n %d of %d', i, numel(edfs) );
  
  edf_file = shared_utils.io.fload( edfs{i} );
  
  un_filename = edf_file.m1.unified_filename;
  
  unified_file = shared_utils.io.fload( fullfile(unified_p, un_filename) );
  
  aligned_filename = fullfile( aligned_p, un_filename );
  
  if ( ~shared_utils.io.fexists(aligned_filename) )
    fprintf( '\n Skipping "%s" because it is missing an aligned file.', un_filename );
    continue;
  end
  
  aligned_file = shared_utils.io.fload( aligned_filename );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  fields = { 'm1', 'm2' };
  
  for j = 1:numel(fields)
    m_name = fields{j};
    if ( ~isfield(edf_file.(m_name).edf.Events, 'Efix') )
      fprintf( '\n Warning: missing Efix for "%s".', un_filename );
      edf_file.(m_name).edf.Events.Efix = struct( 'start', [], 'end', [] );
    end
  end
  
  m1 = edf_file.m1;
  m2 = edf_file.m2;
  
  if ( isempty(m1.edf) ), continue; end
  
  mat_id_times = aligned_file.m1.time;
  
  m1_edf = m1.edf;
  m2_edf = m2.edf;
  
  m1t = get_sync_times( m1_edf );
  m2t = get_sync_times( m2_edf );
  
  sync_m1 = unified_file.m1.sync_times(:, 1);
  sync_m1_m2 = unified_file.m2.sync_times(:, 2);
  sync_m2 = unified_file.m2.sync_times(:, 1);
  
  %   remove the first sync time, because the first sync time is the start
  %   pulse to plexon, rather than a RESYNCH command to eyelink
  edf_sync_m1 = unified_file.m1.plex_sync_times(2:end);
  edf_sync_m2 = unified_file.m2.plex_sync_times(2:end);
  
  try
    assert( numel(m1t) == numel(edf_sync_m1), 'Mismatch between .mat and .edf sync times.' );
    assert( numel(m2t) == numel(edf_sync_m2), 'Mismatch between .mat and .edf sync times.' );
  catch err
    fprintf( '\n WARNING: %s; truncating "%s".', err.message, unified_file.m1.unified_filename );
    n = min( numel(m1t), numel(m2t) );
    m1t = m1t(1:n);
    m2t = m2t(1:n);
    edf_sync_m1 = edf_sync_m1(1:n);
    edf_sync_m2 = edf_sync_m2(1:n);
    sync_m1 = sync_m1(1:n);
    sync_m1_m2 = sync_m1_m2(1:n);
    sync_m2 = sync_m2(1:n);
  end
  
  m1_edf_start = m1_edf.Samples.time(1);
  m2_edf_start = m2_edf.Samples.time(1);
  
  m1t_ = m1t - m1_edf_start;
  m2t_ = m2t - m2_edf_start;
  
  m1_fix_starts = m1_edf.Events.Efix.start - m1_edf_start;
  m1_fix_ends = m1_edf.Events.Efix.end - m1_edf_start;
  
  m2_fix_starts = m2_edf.Events.Efix.start - m2_edf_start;
  m2_fix_ends = m2_edf.Events.Efix.end - m2_edf_start;
  
  %   convert from eyelink -> m1 matlab time
  m1_mat_starts = to_mat_time( m1_fix_starts, m1t_, edf_sync_m1 );
  m1_mat_ends = to_mat_time( m1_fix_ends, m1t_, edf_sync_m1 );
  
  %   convert from eyelink -> m2 matlab time
  m2_mat_starts = to_mat_time( m2_fix_starts, m2t_, edf_sync_m2 );
  m2_mat_ends = to_mat_time( m2_fix_ends, m2t_, edf_sync_m2 );
  
  assert( numel(m1_mat_starts) == numel(m1_mat_ends) && ... 
    numel(m2_mat_starts) == numel(m2_mat_ends) );
  
  m1_keep_gt_0 = m1_mat_starts >= 0 & m1_mat_ends >= 0;
  m2_keep_gt_0 = m2_mat_starts >= 0 & m2_mat_ends >= 0;
  
  m1_mat_starts = m1_mat_starts( m1_keep_gt_0 );
  m1_mat_ends = m1_mat_ends( m1_keep_gt_0 );
  
  m2_mat_starts = m2_mat_starts( m2_keep_gt_0 );
  m2_mat_ends = m2_mat_ends( m2_keep_gt_0 );
  
  %   now convert from m1 matlab time -> m2 matlab time
  m1_mat_starts = bfw.clock_a_to_b( m1_mat_starts, sync_m1_m2, sync_m2 );
  m1_mat_ends = bfw.clock_a_to_b( m1_mat_ends, sync_m1_m2, sync_m2 );
  
  [m1_is_fixation, m1_start_indices, m1_stop_indices] = time_stamps_to_logical( mat_id_times, m1_mat_starts, m1_mat_ends );
  [m2_is_fixation, m2_start_indices, m2_stop_indices] = time_stamps_to_logical( mat_id_times, m2_mat_starts, m2_mat_ends );
  
  fix_struct = struct();
  fix_struct.m1.time = mat_id_times;
  fix_struct.m1.is_fixation = m1_is_fixation;
  fix_struct.m1.start_indices = m1_start_indices;
  fix_struct.m1.stop_indices = m1_stop_indices;
  
  fix_struct.m2.time = mat_id_times;
  fix_struct.m2.is_fixation = m2_is_fixation;
  fix_struct.m2.start_indices = m2_start_indices;
  fix_struct.m2.stop_indices = m2_stop_indices;
  fix_struct.unified_filename = un_filename;
  
  shared_utils.io.require_dir( output_p );
  
  do_save( output_filename, fix_struct );
end

end

function do_save( filepath, fix_struct )

save( filepath, 'fix_struct' );

end

function [out, start_indices, stop_indices] = time_stamps_to_logical( id_times, event_starts, event_stops )

assert( numel(event_starts) == numel(event_stops) );

out = false( size(id_times) );
start_indices = zeros( size(event_starts) );
stop_indices = zeros( size(event_stops) );

for j = 1:numel(event_starts)
  c_start = event_starts(j);
  c_end = event_stops(j);
  
  [~, i_start] = min( abs(id_times - c_start) );
  [~, i_stop] = min( abs(id_times - c_end) );
  
  assert( i_stop >= i_start );
  
  out(i_start:i_stop) = true;
  start_indices(j) = i_start;
  stop_indices(j) = i_stop;
end

end

function t = to_mat_time( eyelink_evt_ts, eyelink_t, mat_t )

t = bfw.clock_a_to_b( eyelink_evt_ts, eyelink_t, mat_t*1e3 ) / 1e3;

end

function t = get_sync_times(edf)

msgs = edf.Events.Messages.info;

msg_ind = strcmp( msgs, 'RESYNCH' );

t = edf.Events.Messages.time( msg_ind );

end