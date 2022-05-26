delete_dirs = { 'sync', 'unified' };

%%

backup_dirs = { 'sync', 'unified' };

src_p = '/media/chang/T41/data/bfw/stim-task-siqi/intermediates';
dst_p = '/media/chang/T41/data/bfw/stim-task-siqi/backup-intermediates';
dst_containing = '01312022';

for i = 1:numel(backup_dirs)
  backup_src_p = fullfile( src_p, backup_dirs{i} );
  ms = shared_utils.io.findmat( backup_src_p );
  ms = ms(contains(ms, dst_containing));
  
  backup_dst_p = fullfile( dst_p, backup_dirs{i} );
  shared_utils.io.require_dir( backup_dst_p );
  for j = 1:numel(ms)
    [~, fname, ext] = fileparts(ms{j});
    copyfile( ms{j}, fullfile(backup_dst_p, sprintf('%s%s',fname,ext)) );  
  end
end

%%

rm_dirs = { 'sync' };
rm_src_p = '/media/chang/T41/data/bfw/stim-task-siqi/intermediates';

for i = 1:numel(rm_dirs)
  rm_files = shared_utils.io.findmat( fullfile(rm_src_p, rm_dirs{i}) );
  rm_files = rm_files(contains(rm_files, dst_containing));
  for j = 1:numel(rm_files)
    delete( rm_files{j} );
  end
end

%%

un_files = shared_utils.io.findmat( fullfile(dst_p, 'unified') );
un_files = un_files(contains(un_files, dst_containing));
for i = 1:numel(un_files)
  un_f = load( un_files{i} );
  fs = intersect( fieldnames(un_f.data), {'m1', 'm2'} );
  
  store_ind = 0;
  for j = 1:numel(fs)
    un_f.data.(fs{j}).plex_sync_index = un_f.data.(fs{j}).plex_sync_index - 1;
    if ( j == 1 )
      store_ind = un_f.data.(fs{j}).plex_sync_index;
    else
      assert( store_ind == un_f.data.(fs{j}).plex_sync_index );
    end
  end
  
  save_p = fullfile( src_p, 'unified', shared_utils.io.filenames(un_files{i}, true) );
  data = un_f.data;
  save( save_p, 'data' );
end