function labs = get_region_labels(labs)

map = get_region_map();

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

function m = get_region_map()

m = containers.Map();

m('04202018') = 'dmpfc';
m('04242018') = 'dmpfc';
m('04252018') = 'ofc';
m('08242018') = 'accg';
m('08272018') = 'ofc_bla';
m('08282018') = 'ofc_bla';
m('08292018') = 'ofc_bla';
m('08302018') = 'ofc_bla_dmpfc';
m('08312018') = 'accg_bla_dmpfc';
m('09042018') = 'accg_bla_dmpfc';
m('09072018') = 'dmpfc';
m('09082018') = 'dmpfc';
m('09102018') = 'accg';
m('09112018') = 'accg';
m('09122018') = 'accg';
m('09132018') = 'accg';
m('09152018') = 'dmpfc';
m('09162018') = 'ofc';
m('09172018') = 'ofc';
m('09182018') = 'ofc';
m('09192018') = 'ofc';
m('09202018') = 'dmpfc';
m('09252018') = 'accg';
m('09272018') = 'accg_bla';
m('09292018') = 'ofc_bla';
m('09302018') = 'ofc_bla';
m('10012018') = 'accg_bla_dmpfc';
m('10022018') = 'accg_bla_dmpfc';
m('10112018') = 'dmpfc';
m('10152018') = 'accg';
m('10162018') = 'ofc';
m('10172018') = 'ofc';
m('10182018') = 'accg';
m('10192018') = 'dmpfc';
m('10222018') = 'dmpfc';
m('10232018') = 'ofc';
m('10242018') = 'accg';

m('07182019') = 'dmpfc';
m('07192019') = 'ofc';
m('07202019') = 'ofc';
m('07222019') = 'accg';
m('07232019') = 'dmpfc';
m('07252019') = 'accg';
m('07262019') = 'dmpfc';
m('07302019') = 'accg';
m('07312019') = 'ofc';
m('08012019') = 'ofc';
m('08022019') = 'accg';
m('08032019') = 'dmpfc';
m('08052019') = 'ofc';
m('08062019') = 'ofc';
m('08072019') = 'accg';
m('08082019') = 'accg';
m('08092019') = 'dmpfc';
m('08122019') = 'ofc';
m('08132019') = 'ofc';
m('08142019') = 'dmpfc';
m('08152019') = 'dmpfc';
m('08202019') = 'ofc';
m('08212019') = 'dmpfc';
m('08222019') = 'accg';
m('08232019') = 'accg';
m('08242019') = 'ofc';
m('08292019') = 'ofc';
m('09032019') = 'dmpfc';
m('09052019') = 'ofc';




end