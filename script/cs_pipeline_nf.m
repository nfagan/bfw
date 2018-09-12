folders = { '09112018' };
file_spec = folders;
% file_spec = [ file_spec, '04242018_position_2' ];

conf = bfw.config.load();

shared_inputs = { 'files_containing', file_spec, 'overwrite', false, 'config', conf };

%%

bfw.make_cs_sync_times( shared_inputs{:} );

%%  

bfw.make_cs_edfs( shared_inputs{:} );

%%

bfw.make_cs_task_events( shared_inputs{:} );