conf = bfw.config.load();

session_types = bfw.get_sessions_by_stim_type( conf );

eyes_sessions = session_types.m1_radius_sessions;
face_sessions = session_types.m1_radius_sessions;

select_files = csunion( eyes_sessions, face_sessions );

%%

amp_vel_outs = bfw_stim_amp_vs_vel( ...
    'look_ahead', 5 ...
  , 'files_containing', select_files ...
  , 'config', conf ...
);

amps = amp_vel_outs.amps;
vels = amp_vel_outs.velocities;
labs = amp_vel_outs.labels';

prune( bfw.get_region_labels(labs) );

%%

pl = plotlabeled();

pltlabs = labs';

X = amps;
Y = vels;

mask = fcat.mask( pltlabs ...
  , @find, 'm1' ...
  , @findnone, '10112018_position_1.mat' ...
  , @find, 'accg' ...
);

fcats = { 'region' };
gcats = { 'stim_type' };
pcats = { 'task_type', 'region' };

I = findall( pltlabs, fcats, mask );

for i = 1:numel(I)

  [axs, ids] = pl.scatter( X(I{i}), Y(I{i}), pltlabs(I{i}), gcats, pcats );
  
end