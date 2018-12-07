function un = try_get_unified_filename(s)

%   TRY_GET_UNIFIED_FILENAME -- Attempt to extract the unified_filename 
%     from file struct.
%
%     un = ... try_get_unified_filename( s ) returns `s.unified_filename`
%     if 'unified_filename' is a field of struct `s`. Otherwise, if `s` is 
%     a struct with fields 'm1' and/or 'm2', `un` will be the first of
%     s.m1.unified_filename or s.m2.unified_filename. Otherwise, an error
%     is thrown.
%
%     IN:
%       - `s` (struct)
%     OUT:
%       - `un` (char)

[un, tf] = get_unified_filename( s );

if ( tf )
  return
end

if ( isfield(s, 'm1') )
  [un, tf] = get_unified_filename( s.m1 );
  
  if ( tf )
    return
  end
end

if ( isfield(s, 'm2') )
  [un, tf] = get_unified_filename( s.m2 );
  
  if ( tf )
    return
  end
end

error( 'Failed to obtain unified filename.' );

end

function [un, tf] = get_unified_filename(s)

un = '';
tf = isfield( s, 'unified_filename' );

if ( ~tf )
  return
end

un = s.unified_filename;

end