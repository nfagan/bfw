conf = bfw.config.load();

repadd( 'chronux', true );
repadd( 'bfw/script' );

if ( isempty(gcp('nocreate')) )
  parpool( feature('numcores') );
end

%%

cs_event_ps = shared_utils.io.findmat( bfw.gid('cs_task_events/m1', conf) );
cs_label_p = bfw.gid( 'cs_labels/m1', conf );

evts = [];
evt_labels = fcat();
for i = 1:numel(cs_event_ps)
  cs_evt_file = shared_utils.io.fload( cs_event_ps{i} );
  fix_col = strcmp( cs_evt_file.event_key, 'fixation' );
  
  try
    cs_labels_file = shared_utils.io.fload( fullfile(cs_label_p, cs_evt_file.cs_unified_filename) );  
  catch err
    continue;
  end
  
  [un_I, un_C] = findall( cs_labels_file.labels, 'cs_unified_filename' );
  for j = 1:numel(un_C)
    sesh = un_C{j}(1:8);
    addsetcat( cs_labels_file.labels, 'session', sesh, un_I{j} );
  end
  
%   addsetcat( cs_labels_file.labels, 'session', 
  evts = [ evts; cs_evt_file.event_times(:, fix_col) ];
  append( evt_labels, cs_labels_file.labels );
end

assert_ispair( evts, evt_labels );

%%

bfw_revisit_sfcoherence_per_session( evts, evt_labels, 'task_type', 'config', conf );