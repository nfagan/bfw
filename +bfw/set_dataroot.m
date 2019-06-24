function conf = set_dataroot(to, conf)

validateattributes( to, {'char'}, {'scalartext'}, mfilename, 'data root' );

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

conf.PATHS.data_root = to;

end