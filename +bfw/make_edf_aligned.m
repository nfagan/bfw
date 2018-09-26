function make_edf_aligned(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();

defaults.fs = 1e3;
defaults.N = 400;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

data_p = bfw.gid( ff('edf', isd), conf );
unified_p = bfw.gid( ff('unified', isd), conf );
edf_sync_p = bfw.gid( ff('edf_sync', isd), conf );
save_p = bfw.gid( ff('aligned', osd), conf );

shared_utils.io.require_dir( save_p );

mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

fs = 1 / params.fs;
N = params.N;

copy_fields = { 'unified_filename' };

allow_overwrite = params.overwrite;

parfor i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  current_edf_file = shared_utils.io.fload( mats{i} );
  
  current_meta = shared_utils.io.fload( fullfile(unified_p, current_edf_file.m1.unified_filename) );
  
  mat_dir = current_meta.m1.mat_directory_name;
  m_filename = current_meta.m1.mat_filename;
  a_filename = bfw.make_intermediate_filename( mat_dir, m_filename );
  
  edf_sync_filename = fullfile( edf_sync_p, a_filename );
  
  %   use corrected sync times for this edf file
  if ( shared_utils.io.fexists(edf_sync_filename) )
    edf_sync_file = shared_utils.io.fload( edf_sync_filename );
  else
    edf_sync_file = [];
  end
  
  output_filename = fullfile( save_p, a_filename );
  
  if ( bfw.conditional_skip_file(output_filename, allow_overwrite) ), continue; end
  
  edf_fields = fieldnames( current_edf_file );
  n_edf_fields = numel( edf_fields );
  
  if ( n_edf_fields ~= 2 )
    %
    %   no need to align in cases where only one subject's computer ran the
    %   task
    %
    assert( n_edf_fields == 1, 'Expected 1 or 2 fields, but got %d', n_edf_fields );
    m_id = edf_fields{1};
    mat_edf_sync = current_meta.(m_id).plex_sync_times(2:end);
    
    aligned = struct();
    
    try 
      edf_obj = current_edf_file.(m_id).edf;
      
      if ( ~isempty(edf_sync_file) )
        edf_sync_times = edf_sync_file.(m_id).edf_sync_times;
      else
        edf_sync_times = get_sync_times( edf_obj );
      end
      
      aligned.(m_id) = dummy_align( edf_obj, edf_sync_times, mat_edf_sync, fs, N );
    catch err
      warning( err.message );
      continue;
    end
  else
    m1 = current_edf_file.m1;
    m2 = current_edf_file.m2;

    if ( isempty(m1.edf) ), continue; end

    m1_edf = m1.edf;
    m2_edf = m2.edf;

    m1t = get_sync_times( m1_edf );
    m2t = get_sync_times( m2_edf );

    if ( strcmp(current_meta.m1.plex_sync_id, 'm2') )
      sync_m1_m2 = current_meta.m2.sync_times(:, 2);
      sync_m2 = current_meta.m2.sync_times(:, 1);
    else
      sync_m1_m2 = current_meta.m1.sync_times(:, 1);
      sync_m2 = current_meta.m1.sync_times(:, 2);
    end

    %   remove the first sync time, because the first sync time is the start
    %   pulse to plexon, rather than a RESYNCH command to eyelink
    edf_sync_m1 = current_meta.m1.plex_sync_times(2:end);
    edf_sync_m2 = current_meta.m2.plex_sync_times(2:end);

    try
      assert( numel(m1t) == numel(edf_sync_m1), 'Mismatch between .mat and .edf sync times.' );
      assert( numel(m2t) == numel(edf_sync_m2), 'Mismatch between .mat and .edf sync times.' );
    catch err
      fprintf( '\n WARNING: %s; skipping "%s".', err.message, current_meta.m1.unified_filename );
      
      continue;
      
%       n = min( numel(m1t), numel(m2t) );
%       m1t = m1t(1:n);
%       m2t = m2t(1:n);
%       edf_sync_m1 = edf_sync_m1(1:n);
%       edf_sync_m2 = edf_sync_m2(1:n);
%       sync_m1_m2 = sync_m1_m2(1:n);
%       sync_m2 = sync_m2(1:n);
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

    aligned = struct();
    aligned.m1 = m1_aligned;
    aligned.m2 = m2_aligned;
    
  end
  
  fields = fieldnames( aligned );
  
  for j = 1:numel(fields)
    for k = 1:numel(copy_fields)
      aligned.(fields{j}).(copy_fields{k}) = current_edf_file.(fields{j}).(copy_fields{k});
    end
    aligned.(fields{j}).aligned_filename = a_filename;
    aligned.(fields{j}).aligned_directory = save_p;
  end
  
  aligned.params = params;
  
  do_save( aligned, output_filename );
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

function aligned = dummy_align(edf, edf_sync_times, mat_clock, fs, N)

edf_time = edf.Samples.time;

m1_edf_start = edf_time(1);

edf_time = edf_time - m1_edf_start;

edf_clock = edf_sync_times - m1_edf_start;

%   make eyelink clock -> matlab clock  
mat_time = bfw.clock_a_to_b( edf_time, edf_clock, mat_clock*1e3 ) / 1e3;

pos = [edf.Samples.posX(:)'; edf.Samples.posY(:)'];

ind = mat_time >= 0;
pos = pos(:, ind);
mat_time = mat_time(ind);
mat_time = mat_time(:)';

% t = 0:fs:N;
% 
% loop_for = 100;
% 
% for i = 1:loop_for
%   [~, I] = min( abs(mat_time(i) - t) );
% end

aligned = struct( ...
    'position', pos ...
  , 'time', mat_time ...
);

end

