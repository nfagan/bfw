function bfw_fix_12052019(raw_p)

m1_p = fullfile( raw_p, 'm1' );
m2_p = fullfile( raw_p, 'm2' );

m1_pos_mats = shared_utils.io.findmat( m1_p );
m1_dot_mats = shared_utils.io.findmat( fullfile(m1_p, 'nonsocial_control') );

m1_files = [ m1_pos_mats(:); m1_dot_mats(:) ];
is_pos_file = false( size(m1_files) );
is_pos_file(1:numel(m1_pos_mats)) = true;

filenames = cell( size(m1_files) );
sync_indices = nan( size(m1_files) );

for i = 1:numel(m1_files)
  m1_file = shared_utils.io.fload( m1_files{i} );
  filenames{i} = shared_utils.io.filenames( m1_files{i}, true );
  sync_indices(i) = m1_file.plex_sync_index;
end

d = 10;

end