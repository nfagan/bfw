function labs = add_monk_labels(labs)

monkey_ids = bfw.monkey_ids_by_session();

m1_map = monkey_ids.m1;
m2_map = monkey_ids.m2;

assert_hascat( labs, 'session' );
[I, C] = findall( labs, 'session' );

addcat( labs, {'id_m1', 'id_m2'} );

for i = 1:numel(I)
  session_name = C{i};
  
  if ( ~isKey(m1_map, session_name) )
    warning( 'Session "%s" is missing.', session_name );
    
    id_m1 = 'unknown';
    id_m2 = 'unknown';
  else
    id_m1 = m1_map(session_name);
    id_m2 = m2_map(session_name);
  end
  
  id_m1 = sprintf( 'm1_%s', id_m1 );
  id_m2 = sprintf( 'm2_%s', id_m2 );
  
  setcat( labs, 'id_m1', id_m1, I{i} );
  setcat( labs, 'id_m2', id_m2, I{i} );
end

end
