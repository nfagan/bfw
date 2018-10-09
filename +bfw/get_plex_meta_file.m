function [raw, plex_filename] = get_plex_meta_file(conf)

%   GET_PLEX_META_FILE -- Get the raw plex-meta file.
%
%     IN:
%       - `conf` (struct) |OPTIONAL|
%     OUT:
%       - `raw` (cell)
%       - `plex_filename` (char)

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
else
  bfw.util.assertions.assert__is_config( conf );
end

plex_filename = fullfile( conf.PATHS.data_root, 'plex', 'plex-meta.xlsx' );

try
  [~, ~, raw] = xlsread( plex_filename, 'Channels' );
catch err
  error( get_fail_msg(plex_filename, err.message) );
end

end

function m = get_fail_msg(filename, msg)
m = sprintf('Failed to load "%s": %s', filename, msg );
end