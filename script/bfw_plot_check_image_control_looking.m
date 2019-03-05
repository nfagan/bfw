outs = bfw_check_image_control_looking();

%%

pltlabs = outs.labels';
pltdat = outs.looking_duration / 1e3;

pl = plotlabeled.make_common();

pcats = {};
gcats = 'image_monkey';
xcats = 'image_direction';

axs = pl.bar( pltdat, pltlabs, xcats, gcats, pcats );

%%

sync_files = bfw.find_intermediates( 'sync', conf );
meta_p = bfw.gid( 'meta', conf );

plex_sync_times = [];
plex_sync_labs = fcat();

for i = 1:numel(sync_files)
  sync_file = shared_utils.io.fload( sync_files{i} );
  meta_file = shared_utils.io.fload( fullfile(meta_p, bfw.try_get_unified_filename(sync_file)));
  
  c_plex_sync = sync_file.plex_sync(:, 2);
  plex_sync_times = [ plex_sync_times; min(c_plex_sync) ];
  
  append( plex_sync_labs, bfw.struct2fcat(meta_file) );
end

%%