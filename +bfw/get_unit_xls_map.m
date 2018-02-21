function map = get_unit_xls_map(conf)

if ( nargin < 1 )
  conf = bfw.config.load();
end

data_p = fullfile( conf.PATHS.data_root, 'mountain_sort' );

unified = bfw.load_one_intermediate( 'unified' );

xls_fullfile = fullfile( data_p, unified.m1.ms_firings_channel_map_filename );

assert( shared_utils.io.fexists(xls_fullfile) ...
  , 'The channel map file "%s" does not exist.', unified.m1.ms_firings_file_map_filename );

[~, ~, xls_raw] = xlsread( xls_fullfile );

map = bfw.process_unit_xls_map( xls_raw );

end