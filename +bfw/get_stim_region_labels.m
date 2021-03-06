function labs = get_stim_region_labels(labs)

map = get_region_map();

assert_hascat( labs, 'session' );
[I, C] = findall( labs, 'session' );

addcat( labs, 'region' );

for i = 1:numel(I)
  session_name = C{i};
  reg_name = map(session_name);
  
  setcat( labs, 'region', reg_name, I{i} );
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

end