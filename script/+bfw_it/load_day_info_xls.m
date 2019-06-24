function raw = load_day_info_xls(conf)

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

xls_file = fullfile( bfw.dataroot(conf), 'xls', 'day-info.xlsx' );
[~, ~, raw] = xlsread( xls_file );

end