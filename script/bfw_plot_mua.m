per_trial_p = bfw.get_intermediate_directory( 'per_trial_mua' );
mats = bfw.require_intermediate_mats( per_trial_p );

min_isi = 0;

[dat, labs, t, params] = bfw.get_mua_psth( mats ...
  , 'min_interspike_interval', min_isi ...
);

%%

opfunc = @minus;
a = 'eyes';
b = 'face';

spec = cssetdiff( getcats(labs), {'looks_to', 'look_order'} );

[normdat, normlabs] = dsp3.summary_binary_op( dat, labs', spec, a, b, opfunc );

dsp3.summary_binary_setcat( normlabs, a, b, dsp3.underscore(func2str(opfunc)) );

%%

pltlabs = normlabs';
pltdat = normdat;

gcats = { 'looks_by' };
pcats = { 'region', 'looks_to' };

mask = fcat.mask( pltlabs ...
  , @findor,    {'m1', 'mutual'} ...
  , @findnone,  {'outside1', 'mouth', 'ref'} ...
);

pl = plotlabeled.make_common( 'sort_combinations', true, 'x', t );
pl.fig = figure(2);

axs = pl.lines( rowref(pltdat, mask), pltlabs(mask), gcats, pcats );

shared_utils.plot.hold( axs );
shared_utils.plot.add_vertical_lines( axs, 0 );

%%  separate figures

pltlabs = normlabs';
pltdat = normdat;

figcats = { 'looks_by' };
gcats = { 'looks_by' };
pcats = { 'region', 'looks_to' };

mask = fcat.mask( pltlabs ...
  , @findor,    {'m1', 'mutual'} ...
  , @findnone,  {'outside1', 'mouth', 'ref'} ...
);

pl = plotlabeled.make_common( 'sort_combinations', true, 'x', t );

[figs, axs] = pl.figures( @lines, rowref(pltdat, mask), pltlabs(mask), figcats, gcats, pcats );

shared_utils.plot.match_ylims( axs );
shared_utils.plot.hold( axs );
shared_utils.plot.add_vertical_lines( axs, 0 );



