function make_spikes()

conf = bfw.config.load();

data_root = conf.PATHS.data_root;

unified_p = bfw.get_intermediate_directory( 'unified' );

un_mats = shared_utils.io.find( unified_p, '.mat' );

for i = 1:numel(un_mats)
  
  unified = shared_utils.io.fload( un_mats{i} );
  
	fields = fieldnames( unified );
  firstf = fields{1};
  
  pl2_file = unified.(firstf).plex_filename;
  pl2_dir = fullfile( data_root, unified.(firstf).plex_directory{:} );
  
  units = unified
end

end