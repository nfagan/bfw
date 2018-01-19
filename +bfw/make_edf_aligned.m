function make_edf_aligned()

conf = bfw.config.load();

data_p = bfw.get_intermediate_directory( 'unified' );
save_p = bfw.get_intermediate_directory( 'aligned' );

mats = shared_utils.io.find( data_p, '.mat' );

for i = 1:numel(mats)
  current = shared_utils.io.fload( mats{i} );
  
  m1 = current.m1;
  m2 = current.m2;
  
  if ( isempty(m1.edf) )
    continue;
  end
  
  m1_edf = m1.edf;
  m2_edf = m2.edf;
  
  m1t = get_sync_times( m1_edf );
  m2t = get_sync_times( m2_edf );
  
  sync_m1 = m1.sync_times(:, 1);
  sync_m1_m2 = m2.sync_times(:, 2);
  sync_m2 = m2.sync_times(:, 1);
  
  t_m1 = m1_edf.Samples.time;
  t_m2 = m2_edf.Samples.time;
  
  m1_edf_start = t_m1(1);
  m2_edf_start = t_m2(1);
  
  t_m1 = t_m1 - m1_edf_start;
  t_m2 = t_m2 - m2_edf_start;
  
  m1t_ = m1t - m1_edf_start;
  m2t_ = m2t - m2_edf_start;
  
  t_m1_ = bfw.clock_a_to_b( t_m1, m1t_, sync_m1*1e3 ) / 1e3;
  t_m2_ = bfw.clock_a_to_b( t_m2, m2t_, sync_m2*1e3 ) / 1e3;
  
  pos_m1 = [m1_edf.Samples.posX; m1_edf.Samples.posY];
  pos_m2 = [m2_edf.Samples.posY; m2_edf.Samples.posY];

  [pos_aligned, t] = bfw.align_m1_m2( pos_m1, pos_m2, t_m1_, t_m2_, sync_m1_m2, sync_m2, fs, N );
  
  
  
end

end

function t = get_sync_times(edf)

msgs = edf.Events.Messages.info;

msg_ind = strcmp( msgs, 'RESYNCH' );

t = edf.Events.Messages.time( msg_ind );

end