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

m('10112018') = 'hitch';
m('10152018') = 'hitch';
m('10162018') = 'lynch';
m('10172018') = 'hitch';
m('10182018') = 'lynch';
m('10192018') = 'hitch';
m('10222018') = 'hitch';
m('10232018') = 'lynch';
m('10242018') = 'lynch';

% m1 Lynch
m('01022019') = 'cron';
m('01032019') = 'ephron';
m('01042019') = 'cron';
m('01052019') = 'hitch';
m('01062019') = 'hitch';
m('01072019') = 'cron';
m('01082019') = 'ephron';
m('01092019') = 'cron';
m('01102019') = 'ephron';
m('01112019') = 'cron';
m('01132019') = 'hitch';
m('01142019') = 'cron';
m('01152019') = 'ephron';
m('01172019') = 'ephron';

m('07182019') = 'ephron';
m('07192019') = 'ephron';
m('07202019') = 'ephron';
m('07222019') = 'ephron';
m('07232019') = 'ephron';
m('07252019') = 'ephron';
m('07262019') = 'ephron';
m('07302019') = 'ephron';
m('07312019') = 'ephron';
m('08012019') = 'ephron';
m('08022019') = 'ephron';
m('08032019') = 'ephron';
m('08052019') = 'ephron';
m('08062019') = 'ephron';
m('08072019') = 'ephron';
m('08082019') = 'ephron';
m('08092019') = 'ephron';
m('08122019') = 'ephron';
m('08132019') = 'hitch';
m('08142019') = 'ephron';
m('08152019') = 'ephron';
m('08202019') = 'ephron';
m('08212019') = 'ephron';
m('08222019') = 'ephron';
m('08232019') = 'ephron';
m('08242019') = 'ephron';
m('08292019') = 'ephron';
m('09032019') = 'ephron';
m('09052019') = 'ephron';

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
m('10112018') = 'kuro';
m('10152018') = 'kuro';
m('10162018') = 'kuro';
m('10172018') = 'kuro';
m('10182018') = 'kuro';
m('10192018') = 'kuro';
m('10222018') = 'kuro';
m('10232018') = 'kuro';
m('10242018') = 'kuro';

% % Newer
% m('10112018') = 'kuro';
% m('10152018') = 'kuro';
% m('10162018') = 'kuro';
% m('10172018') = 'kuro';
% m('10182018') = 'kuro';
% m('10192018') = 'kuro';
% m('10222018') = 'kuro';

% Lynch
m('01022019') = 'lynch';
m('01032019') = 'lynch';
m('01042019') = 'lynch';
m('01052019') = 'lynch';
m('01062019') = 'lynch';
m('01072019') = 'lynch';
m('01082019') = 'lynch';
m('01092019') = 'lynch';
m('01102019') = 'lynch';
m('01112019') = 'lynch';
m('01132019') = 'lynch';
m('01142019') = 'lynch';
m('01152019') = 'lynch';
m('01172019') = 'lynch';

m('07182019') = 'lynch';
m('07192019') = 'cron';
m('07202019') = 'lynch';
m('07222019') = 'lynch';
m('07232019') = 'cron';
m('07252019') = 'cron';
m('07262019') = 'lynch';
m('07302019') = 'cron';
m('07312019') = 'lynch';
m('08012019') = 'cron';
m('08022019') = 'lynch';
m('08032019') = 'cron';
m('08052019') = 'lynch';
m('08062019') = 'cron';
m('08072019') = 'lynch';
m('08082019') = 'cron';
m('08092019') = 'lynch';
m('08122019') = 'lynch';
m('08132019') = 'cron';
m('08142019') = 'lynch';
m('08152019') = 'cron';
m('08202019') = 'cron';
m('08212019') = 'lynch';
m('08222019') = 'cron';
m('08232019') = 'lynch';
m('08242019') = 'cron';
m('08292019') = 'lynch';
m('09032019') = 'lynch';
m('09052019') = 'lynch';


end
