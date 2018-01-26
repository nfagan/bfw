function make_edf_aligned(mats)

data_p = bfw.get_intermediate_directory( 'edf' );
unified_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'aligned' );

shared_utils.io.require_dir( save_p );

if ( nargin < 1 )
  mats = shared_utils.io.find( data_p, '.mat' );
end

fs = 1/1e3;

N = 400;

copy_fields = { 'unified_directory', 'unified_filename' };

for i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  current = shared_utils.io.fload( mats{i} );
  
  current_meta = shared_utils.io.fload( fullfile(unified_p, current.m1.unified_filename) );
  
  m1 = current.m1;
  m2 = current.m2;
  
  if ( isempty(m1.edf) ), continue; end
  
  m1_edf = m1.edf;
  m2_edf = m2.edf;
  
  m1t = get_sync_times( m1_edf );
  m2t = get_sync_times( m2_edf );
  
  sync_m1 = current_meta.m1.sync_times(:, 1);
  sync_m1_m2 = current_meta.m2.sync_times(:, 2);
  sync_m2 = current_meta.m2.sync_times(:, 1);
  
  %   remove the first sync time, because the first sync time is the start
  %   pulse to plexon, rather than the RESYNCH commands to eyelink
  edf_sync_m1 = current_meta.m1.plex_sync_times(2:end);
  edf_sync_m2 = current_meta.m2.plex_sync_times(2:end);
  
  try
    assert( numel(m1t) == numel(edf_sync_m1), 'Mismatch between .mat and .edf sync times.' );
    assert( numel(m2t) == numel(edf_sync_m2), 'Mismatch between .mat and .edf sync times.' );
  catch err
%     fprintf( '\n WARNING: %s; skipping "%s".', err.message, current_meta.m1.unified_filename );
    fprintf( '\n WARNING: %s; truncating "%s".', err.message, current_meta.m1.unified_filename );
    n = min( numel(m1t), numel(m2t) );
    m1t = m1t(1:n);
    m2t = m2t(1:n);
    edf_sync_m1 = edf_sync_m1(1:n);
    edf_sync_m2 = edf_sync_m2(1:n);
    sync_m1 = sync_m1(1:n);
    sync_m1_m2 = sync_m1_m2(1:n);
    sync_m2(1:n);
%     continue;
  end
  
  t_m1 = m1_edf.Samples.time;
  t_m2 = m2_edf.Samples.time;
  
  m1_edf_start = t_m1(1);
  m2_edf_start = t_m2(1);
  
  t_m1 = t_m1 - m1_edf_start;
  t_m2 = t_m2 - m2_edf_start;
  
  m1t_ = m1t - m1_edf_start;
  m2t_ = m2t - m2_edf_start;
  
  %   make eyelink clock -> matlab clock  
  t_m1_ = bfw.clock_a_to_b( t_m1, m1t_, edf_sync_m1*1e3 ) / 1e3;
  t_m2_ = bfw.clock_a_to_b( t_m2, m2t_, edf_sync_m2*1e3 ) / 1e3;
  
  pos_m1 = [m1_edf.Samples.posX(:)'; m1_edf.Samples.posY(:)'];
  pos_m2 = [m2_edf.Samples.posX(:)'; m2_edf.Samples.posY(:)'];

  [pos_aligned, t] = bfw.align_m1_m2( pos_m1, pos_m2, t_m1_, t_m2_, sync_m1_m2, sync_m2, fs, N );
  
  m1_aligned = struct( ...
      'position', pos_aligned(1:2, :) ...
    , 'time', t ...
  );

  m2_aligned = struct( ...
      'position', pos_aligned(3:4, :) ...
    , 'time', t ...
  );

  mat_dir = current_meta.m1.mat_directory_name;
  m_filename = current_meta.m1.mat_filename;
  
  a_filename = bfw.make_intermediate_filename( mat_dir, m_filename );

  aligned = struct();
  aligned.m1 = m1_aligned;
  aligned.m2 = m2_aligned;
  
  fields = fieldnames( aligned );
  
  for j = 1:numel(fields)
    for k = 1:numel(copy_fields)
      aligned.(fields{j}).(copy_fields{k}) = current.(fields{j}).(copy_fields{k});
    end
    aligned.(fields{j}).aligned_filename = a_filename;
    aligned.(fields{j}).aligned_directory = save_p;
  end
  
  do_save( aligned, fullfile(save_p, a_filename) );
end

end

function do_save( variable, filepath )

save( filepath, 'variable' );

end

function t = get_sync_times(edf)

msgs = edf.Events.Messages.info;

msg_ind = strcmp( msgs, 'RESYNCH' );

t = edf.Events.Messages.time( msg_ind );

end