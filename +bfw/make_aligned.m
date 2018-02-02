function make_aligned(varargin)

defaults = struct();
defaults.files = [];
defaults.files_containing = [];
defaults.fs = 1e3;
defaults.N = 400;

params = bfw.parsestruct( defaults, varargin );

data_p = bfw.get_intermediate_directory( 'unified' );

save_p = bfw.get_intermediate_directory( 'aligned' );

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

fs = 1 / params.fs;

N = params.N;

for i = 1:numel(mats)
  fprintf( '\n Processing %d of %d', i, numel(mats) );
  
  current = shared_utils.io.fload( mats{i} );
  
  m1 = current.m1;
  m2 = current.m2;

  pos_m1 = m1.position;
  pos_m2 = m2.position;

  t_m1 = m1.time;
  t_m2 = m2.time;

  %   transform m1 time points -> m2's clock. it should be m1 -> m2 because 
  %   m2 sends pulses to plexon.

  sync_m1 = m2.sync_times(:, 2);
  sync_m2 = m2.sync_times(:, 1);

  [pos_aligned, t] = bfw.align_m1_m2( pos_m1, pos_m2, t_m1, t_m2, sync_m1, sync_m2, fs, N );
  
  m_filename = m1.mat_filename;
  
  m1_aligned = struct( ...
      'position', pos_aligned(1:2, :) ...
    , 'time', t ...
  );

  m2_aligned = struct( ...
      'position', pos_aligned(3:4, :) ...
    , 'time', t ...
  );

  mat_dir = m1.mat_directory_name;
  
  a_filename = bfw.make_intermediate_filename( mat_dir, m_filename );

  aligned = struct();
  aligned.m1 = m1_aligned;
  aligned.m2 = m2_aligned;
  
  fields = fieldnames( aligned );
  
  for j = 1:numel(fields)
    aligned.(fields{j}).unified_directory = m1.unified_directory;
    aligned.(fields{j}).unified_filename = m1.unified_filename;
    aligned.(fields{j}).aligned_filename = a_filename;
    aligned.(fields{j}).aligned_directory = save_p;
  end

  shared_utils.io.require_dir( save_p );
  save( fullfile(save_p, a_filename), 'aligned' );
end

end


