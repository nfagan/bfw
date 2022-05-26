function [f, cache] = load_linked(p, cache)

f = shared_utils.io.fload( p );
fname = shared_utils.io.filenames( p, true );

if ( f.is_link )
  if ( nargin > 1 && cache.isKey(f.data_file) )
    f = cache(f.data_file);
    return
  end
  f = shared_utils.io.fload( fullfile(fileparts(p), f.data_file) );   
end

if ( nargin > 1 && ~cache.isKey(fname) )
  cache(fname) = f;
end

end