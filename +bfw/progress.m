function progress(n, N, file)

if ( nargin < 3 )
  fprintf( '\n %d of %d', n, N );
else
  fprintf( '\n %s: %d of %d', file, n, N );
end

end