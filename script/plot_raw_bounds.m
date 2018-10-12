conf = bfw.config.load();

outs = get_stim_aligned_samples( ...
    'config',             conf ...
  , 'fixations_subdir',   'arduino_fixations' ...
  , 'samples_subdir',     'aligned_binned_raw_samples' ...
);

ib_labs = outs.labels';
is_ib = outs.is_in_bounds;
is_fix = outs.is_fixation;
ib_t = outs.t;

%%

use_fix = false;

if ( use_fix )
  is_valid = double( is_ib & is_fix );
else
  is_valid = double( is_ib );
end

spec = { 'looks_by', 'roi', 'stim_type', 'session', 'unified_filename' };

[plabs, I] = keepeach( ib_labs', spec );
pdat = rowmean( is_valid, I );

prune( bfw.get_region_labels(plabs) );

%%

pltdat = pdat;
pltlabs = plabs';

mask = fcat.mask( plabs, @find, {'eyes_nf', 'm1', '09102018'} );

adjust = 0.05;

pl = plotlabeled.make_common();
pl.x = ib_t;
pl.y_lims = [-adjust, adjust + 1];

gcats = { 'stim_type' };
pcats = { 'looks_by', 'roi' };

axs = pl.lines( pdat(mask, :), plabs(mask), gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [-0.15, 0], 'k--' );