function conf = get_nf_local_conf(conf)

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

conf.PATHS.data_root = get_nf_local_dataroot();

end