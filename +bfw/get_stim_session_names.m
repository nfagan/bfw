function n = get_stim_session_names(conf)

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

un_p = bfw.gid( 'unified', conf );
un_mats = bfw.rim( un_p );

for i = 1:numel(un_mats)
  shared_utils.general.progress( i, numel(un_mats), mfilename );
  
  d = 10;
end

end