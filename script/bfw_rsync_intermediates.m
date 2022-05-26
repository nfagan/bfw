function bfw_rsync_intermediates(src_root, dst_root, int_ps, varargin)

defaults = struct();
defaults.host = 'chang@172.28.28.72';
params = shared_utils.general.parsestruct( defaults, varargin );

int_ps = cellstr( int_ps );

host = params.host;

if ( ~shared_utils.io.dexists(dst_root) )
  error( 'Folder does not exist: %s.', dst_root );
end

for i = 1:numel(int_ps)
  int_p = int_ps{i};

  dst_p = fullfile( dst_root, 'intermediates', int_p );
  src_p = fullfile( src_root, 'intermediates', int_p );

  shared_utils.io.require_dir( dst_p );
  cmd = sprintf( 'rsync %s:%s/*.mat %s', host, src_p, dst_p );

  system( cmd );  
end

end