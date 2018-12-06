conf = bfw.config.load();

session_types = bfw.get_sessions_by_stim_type( conf );

select_files = csunion( session_types.m1_exclusive_sessions, session_types.m1_radius_sessions );

%%

evt_outs = bfw_stim_amp_vs_vel( ...
    'config', conf ...
  , 'look_ahead', 5 ...
  , 'files_containing', select_files ...
);

labs = evt_outs.labels';
ib = evt_outs.traces;
is_fix = evt_outs.traces;
t = evt_outs.t;
samples = evt_outs.samples;
sample_key = evt_outs.samples_key;

prune( bfw.get_region_labels(labs) );

%%

pos = samples(:, sample_key('position'));
t = samples(:, sample_key('t'));

non_empties = find( ~cellfun(@isempty, pos) );

amp = rownan( numel(non_empties) );

for i = 1:numel(non_empties)
  p = pos{non_empties(i)};
  t0 = t{non_empties(i)};
  
  if ( numel(t0) < 2 ), continue; end
end