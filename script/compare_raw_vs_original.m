%%

conf = bfw.config.load();

outs = get_stim_aligned_samples( ...
    'config',             conf ...
  , 'fixations_subdir',   'arduino_fixations' ...
  , 'samples_subdir',     'aligned_binned_raw_samples' ...
);

[outs2, t2] = debug_stim_times();

%%

use_aligned = true;

if ( use_aligned )
  ib_labs = outs.labels';
  is_ib = outs.is_in_bounds;
  is_fix = outs.is_fixation;
  ib_t = outs.t;
else
  
  ib_labs = outs2.labs';
  is_ib = outs2.ib;
  is_fix = outs2.is_fix;
  ib_t = t2;
  
  addsetcat( ib_labs, 'looks_by', 'm1' );  
end

%%

use_fix = true;

if ( use_fix )
  is_valid = double( is_ib & is_fix );
else
  is_valid = double( is_ib );
end

spec = { 'looks_by', 'roi', 'stim_type', 'session', 'unified_filename' };

[plabs, I] = keepeach( ib_labs', spec );
pdat = rowmean( is_valid, I );

prune( bfw.get_stim_region_labels(plabs) );

%%

pltdat = pdat;
pltlabs = plabs';

mask = fcat.mask( plabs, @find, {'eyes_nf', 'm1'} );

adjust = 0.05;

pl = plotlabeled.make_common();
pl.x = ib_t;
pl.y_lims = [-adjust, adjust + 1];

gcats = { 'stim_type' };
pcats = { 'looks_by', 'roi' };

axs = pl.lines( pdat(mask, :), plabs(mask), gcats, pcats );

shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [-0.15, 0], 'k--' );