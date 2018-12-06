function un = try_get_unified_filename(s)

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