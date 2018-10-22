conf = bfw.config.load();

select_files = {};

aligned_outs = get_stim_aligned_samples( ...
    'config', conf ...
  , 'look_back', -1 ...
  , 'look_ahead', 5 ...
  , 'pad_bounds', 0.05 ...
  , 'samples_subdir', 'aligned_raw_samples' ...
  , 'files_containing', select_files ...
);

%%

labs = aligned_outs.labels';

mask = fcat.mask( labs ...
  , @findnone, {'04202018', '10112018_position_1.mat'} ...
  , @find, {'m1', 'eyes_nf'} ...
  , @findnone, {'10112018', '10152018', '10162018', '10172018', '10182018', '10192018'} ...
);

debug_check_oob_stim( ...
    'labels', labs' ...
  , 't', aligned_outs.t ...
  , 'traces', aligned_outs.is_in_bounds ...
  , 'rois', aligned_outs.rois ...
  , 'x', aligned_outs.x ...
  , 'y', aligned_outs.y ...
  , 'mask', mask ...
);

%%

use_fix = false;
use_ib = true;

labs = aligned_outs.labels';
t = aligned_outs.t;
traces = aligned_outs.is_in_bounds;

if ( use_fix ), traces = traces & aligned_outs.is_fixation; end

traces = double( traces );

t0_ind = t >= -0.01 & t <= 0.01;
is_oob = ~any( traces(:, t0_ind), 2 );

% t_ind = t >= -0.01 & t <= 0.01;
t_ind = true( size(t) );

pltlabs = labs';
pltdat = traces;

prune( bfw.get_region_labels(pltlabs) );

mask = fcat.mask( pltlabs ...
  , @findnone, {'04202018', '10112018_position_1.mat'} ...
  , @find, {'m1', 'eyes_nf'} ...
  , @findnone, {'10112018', '10152018', '10162018', '10172018', '10182018', '10192018'} ...
);

if ( use_ib ), mask = intersect( mask, find(~is_oob) ); end

[y, I] = keepeach( pltlabs', {'stim_type', 'unified_filename'}, mask );
ps = rowmean( pltdat, I );

pl = plotlabeled.make_common();
pl.add_errors = false;
pl.x = t(t_ind);
pl.add_legend = false;

figure(1);
clf();

gcats = { 'stim_type' };
pcats = { 'region', 'roi', 'looks_by', 'task_type' };

axs = pl.lines( ps(:, t_ind), y, gcats, pcats );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, 0 );
shared_utils.plot.add_horizontal_lines( axs, 0.99 );
shared_utils.plot.set_ylims( axs, [0.9, 1] );
shared_utils.plot.set_xlims( axs, [-0.2, 0.2] );
shared_utils.plot.match_xlims( axs );

%%  bar

t0_ind = t >= -0.01 & t <= 0;
% assert( nnz(t0_ind) == 1 );

t0_meaned = double( any(traces(:, t0_ind), 2) );

pltlabs = labs';
pltdat = t0_meaned;

prune( bfw.get_region_labels(pltlabs) );

mask = fcat.mask( pltlabs ...
  , @findnone, {'04202018', '10112018_position_1.mat'} ...
  , @find, {'m1', 'eyes_nf'} ...
  , @findnone, {'10112018', '10152018', '10162018', '10172018'} ...
  , @findnone, 'nonsocial_control' ...
);

figure(1);
clf();

[y, I] = keepeach( pltlabs', {'stim_type', 'unified_filename'}, mask );

ps = rowmean( pltdat, I );

pl = plotlabeled.make_common();
pl.add_errors = false;
pl.y_lims = [0.9, 1];

axs = pl.bar( ps, y, 'stim_type', 'region', {'roi', 'looks_by', 'task_type'} );