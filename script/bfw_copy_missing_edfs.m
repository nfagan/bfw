function bfw_copy_missing_edfs(src_p, dst_p, host)

if ( ~shared_utils.io.dexists(dst_p) )
  error( 'Folder "%s" does not exist.', dst_p );
end

if ( nargin < 3 )
  host = 'chang@172.28.28.72';
end

dst_un_p = fullfile( dst_p, 'intermediates/unified' );
% dst_edf_p = fullfile( dst_p, 'edf' );
shared_utils.io.require_dir( dst_un_p );

dst_raw_p = fullfile( dst_p, 'raw' );
shared_utils.io.require_dir( dst_raw_p );

src_un_p = fullfile( src_p, 'unified' );

curr_uns = bfw_remote_list_files( '.mat', src_un_p, host );
curr_edfs = bfw_remote_list_files( '.mat', fullfile(src_p, 'edf'), host );
miss_edfs = setdiff( curr_uns, curr_edfs );

uns = cell( size(miss_edfs) );
for i = 1:numel(miss_edfs)  
  cmd = sprintf( 'scp %s:%s/%s %s', host, src_un_p, miss_edfs{i}, dst_un_p );
  system( cmd );
  uns{i} = shared_utils.io.fload( fullfile(dst_un_p, miss_edfs{i}) );
end

%%

for i = 1:numel(uns)
  fs = intersect( fieldnames(uns{i}), {'m1', 'm2'} );
  for j = 1:numel(fs)
    un = uns{i}.(fs{j});
    mat_comp = fullfile( un.mat_directory{2:end} );
    src_edf = fullfile( fileparts(src_p), 'raw', mat_comp, un.edf_filename );
    dst_edf = fullfile( dst_raw_p, mat_comp, un.edf_filename ); 
    shared_utils.io.require_dir( fileparts(dst_edf) );
    cmd = sprintf( 'scp %s:%s %s', host, src_edf, dst_edf );
    system( cmd );
  end
end

end