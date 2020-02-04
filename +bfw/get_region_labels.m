function labs = get_region_labels(labs)

map = bfw.regions_by_session();

assert_hascat( labs, 'session' );
[I, C] = findall( labs, 'session' );

addcat( labs, 'region' );

for i = 1:numel(I)
  session_name = C{i};
  
  if ( isKey(map, session_name) )
    reg_name = map(session_name);
    setcat( labs, 'region', reg_name, I{i} );
  else
    warning( 'No region defined for "%s".', session_name );
  end
end

end