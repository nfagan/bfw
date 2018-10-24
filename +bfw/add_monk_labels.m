function labs = add_monk_labels(labs)

m1_map = get_m1_map();
m2_map = get_m2_map();

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

function m = get_m2_map()

m = containers.Map();
m('01162018') = 'ephron';
m('01172018') = 'ephron';
m('01192018') = 'ephron';
m('01302018') = 'ephron';
m('01312018') = 'lynch';
m('02022018') = 'lynch';
m('02042018') = 'ephron';
m('02052018') = 'lynch';
m('02062018') = 'ephron';
m('02072018') = 'ephron';
m('02082018') = 'ephron';
m('02092018') = 'ephron';

m('04202018') = 'ephron';
m('04242018') = 'ephron';
m('04252018') = 'ephron';

m('08102018') = 'ephron';

m('08242018') = 'lynch';
m('08272018') = 'lynch';
m('08282018') = 'ephron';
m('08292018') = 'lynch';
m('08302018') = 'lynch';
m('08312018') = 'lynch';
m('09042018') = 'lynch';

m('09072018') = 'lynch';
m('09082018') = 'ephron';
m('09102018') = 'ephron';
m('09112018') = 'lynch';
m('09122018') = 'ephron';
m('09132018') = 'lynch';
m('09152018') = 'lynch';
m('09162018') = 'lynch';
m('09172018') = 'ephron';
m('09182018') = 'lynch';
m('09192018') = 'ephron';
m('09202018') = 'lynch';

m('09252018') = 'ephron';
m('09272018') = 'hitch';
m('09292018') = 'hitch';
m('09302018') = 'hitch';
m('10012018') = 'hitch';
m('10022018') = 'hitch';
m('10032018') = 'hitch';
m('10042018') = 'hitch';
m('10092018') = 'hitch';
m('10102018') = 'hitch';

end

function m = get_m1_map()

m = containers.Map();
m('01162018') = 'kuro';
m('01172018') = 'kuro';
m('01192018') = 'kuro';
m('01302018') = 'kuro';
m('01312018') = 'kuro';
m('02022018') = 'kuro';
m('02042018') = 'kuro';
m('02052018') = 'kuro';
m('02062018') = 'kuro';
m('02072018') = 'kuro';
m('02082018') = 'kuro';
m('02092018') = 'kuro';

m('04202018') = 'kuro';
m('04242018') = 'kuro';
m('04252018') = 'kuro';

m('08102018') = 'kuro';

m('08242018') = 'kuro';
m('08272018') = 'kuro';
m('08282018') = 'kuro';
m('08292018') = 'kuro';
m('08302018') = 'kuro';
m('08312018') = 'kuro';
m('09042018') = 'kuro';

m('09072018') = 'kuro';
m('09082018') = 'kuro';
m('09102018') = 'kuro';
m('09112018') = 'kuro';
m('09122018') = 'kuro';
m('09132018') = 'kuro';
m('09152018') = 'kuro';
m('09162018') = 'kuro';
m('09172018') = 'kuro';
m('09182018') = 'kuro';
m('09192018') = 'kuro';
m('09202018') = 'kuro';

m('09252018') = 'kuro';
m('09272018') = 'kuro';
m('09292018') = 'kuro';
m('09302018') = 'kuro';
m('10012018') = 'kuro';
m('10022018') = 'kuro';
m('10032018') = 'kuro';
m('10042018') = 'kuro';
m('10092018') = 'kuro';
m('10102018') = 'kuro';

end
