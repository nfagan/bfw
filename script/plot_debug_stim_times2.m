conf = bfw.config.load();

conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/free_viewing';

look_ahead = 5;
look_back = -1;

[outs, t, params] = debug_stim_times( ...
    'config',     conf ...
  , 'look_ahead', look_ahead ...
  , 'look_back',  look_back ...
);

labs = outs.labs';

ib = outs.ib;
is_fix = outs.is_fix;
x = outs.x;
y = outs.y;

%%

import shared_utils.vector.slidebin;

wsize = 10;
ssize = 10;
discard_uneven = true;

[runlabs, I] = keepeach( labs', {'unified_filename', 'stim_type', 'roi'} );

p = rowop( double(ib & is_fix), I, @(x) sum(x, 1) / rows(x) );

binned_t = cellfun( @median, slidebin(t, wsize, ssize, discard_uneven) );
binned_p = logical([]);

binned_p_func = @all;

for i = 1:size(p, 1)
  binned_p(end+1, :) = cellfun( binned_p_func, slidebin(p(i, :), wsize, ssize, discard_uneven) );
end

%%

for i = 1:size(p, 1)
  
end


%%

use_binned = true;

pltdat = ternary( use_binned, double(binned_p), p );
pltt = ternary( use_binned, binned_t, t );
pltlabs = runlabs';

pl = plotlabeled.make_common();
pl.x = pltt;
pl.y_lims = [0, 1];

mask = fcat.mask( pltlabs, @find, {'eyes_nf'} );
gcats = { 'stim_type' };
pcats = { 'roi' };

figure(1);
clf();

axs = pl.lines( pltdat(mask, :), pltlabs(mask), gcats, pcats );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [-0.15, 0] );
