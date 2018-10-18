conf = bfw.config.load();

tic;

evt_outs = debug_raw_look_back( ...
    'config',    conf ...
  , 'look_back', -1 ...
  , 'look_ahead', 5 ...
  , 'keep_within_threshold', 0.3 ...
);

toc;

%%

labs = evt_outs.labels';
traces = evt_outs.traces;
is_within_thresh = evt_outs.is_within_threshold;
offsets = evt_outs.event_offsets;
t = evt_outs.t;

%%

pltlabs = labs';
pltdat = traces;

use_within_thresh = false;

prune( bfw.get_region_labels(pltlabs) );

if ( use_within_thresh )
  mask = find( is_within_thresh );
else
  mask = rowmask( pltlabs );
end

mask = fcat.mask( pltlabs, mask ...
  , @findnone, {'04202018', 'nonsocial_control', '10112018_position_1.mat'} ...
  , @find, {'m1', 'eyes_nf'} ...
  , @find, {'10112018', '10152018', '10162018', '10172018'} ...
);

figure(1);
clf();

[y, I] = keepeach( pltlabs', {'stim_type', 'unified_filename'}, mask );

ps = rowmean( pltdat, I );

pl = plotlabeled.make_common();
pl.add_errors = false;
pl.x = t;
pl.y_lims = [0, 1];
% pl.shape = [3, 1];

axs = pl.lines( ps, y, 'stim_type', {'region', 'roi', 'looks_by'} );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [0, -0.15] );

% arrayfun( @(x) xlim(x, [-1, 1]), axs );