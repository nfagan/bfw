%days = { '0827', '0829', '0830', '0831', '0904', '0907', '0908', '0910' };
%days = { '0829' };
%days = cellfun( @(x) sprintf('%s2018', x), days, 'un', 0 );

days = { '11', '12', '13', '15', '16', '17', '18', '19', '20' };

days = cellfun( @(x) sprintf('09%s2018', x), days, 'un', 0 );

folders = days;

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