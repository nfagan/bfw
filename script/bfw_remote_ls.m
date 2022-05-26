function [files, out] = bfw_remote_ls(path, host)

if ( nargin < 2 )
  host = 'chang@172.28.28.72';
end

fprintf( ['\n You may be prompted for a password, but this prompt' ...
  , '\n will not appear. If the program appears to be stalled, try entering' ...
  , '\n your ssh password and hit enter.\n'] );

[~, out] = system( sprintf('ssh %s ls -l %s', host, path) );

hostname = strsplit( host, '@' );
hostname = hostname{1};
lines = strsplit( out, newline );
files = lines(contains(lines, sprintf('%s %s', hostname, hostname)));

end