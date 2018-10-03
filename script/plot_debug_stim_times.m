
[outs, t, params] = debug_stim_times();

ib = outs.ib;
is_fix = outs.is_fix;
labs = outs.labs';
x = outs.x;
y = outs.y;

%%

dat = shared_utils.io.fload( fullfile(bfw.dataroot(), 'tmp', 'debug_stim_pad_with_fix.mat') );

ib = dat.ib;
is_fix = dat.is_fix;
labs = dat.labs';
t = dat.t;

%%

import shared_utils.io.fload;

base_p = fullfile( bfw.dataroot, 'tmp' );

load_pos = true;

ib = fload( fullfile(base_p, 'debug_stim_ib.mat') );
is_fix = fload( fullfile(base_p, 'debug_stim_is_fix.mat') );
t = fload( fullfile(base_p, 'debug_stim_t.mat') );
labs = fload( fullfile(base_p, 'debug_stim_labs.mat') );

if ( load_pos )
  x = fload( fullfile(base_p, 'debug_stim_x.mat') );
  y = fload( fullfile(base_p, 'debug_stim_y.mat') );
end

%%  lines

figure(2);
clf();

trial = 1;

plot( t, x(trial, :), 'r' );
hold on;

lims = get( gca, 'ylim' );
pad = 0.2;
lims = [ lims(1) + (lims(2)-lims(1))*pad, lims(2) - (lims(2)-lims(1))*pad ];

vals = repmat( lims(1), size(t) );
vals(is_fix(trial, :) == 1) = lims(2);

plot( t, vals, 'b' );

%%  dots

figure(2);
clf();

trial = 1;

plot( t, x(trial, :), 'r' );
hold on;
plot( t, y(trial, :), 'b' );

lims = get( gca, 'ylim' );
pad = 0.2;
lims = [ lims(1) + (lims(2)-lims(1))*pad, lims(2) - (lims(2)-lims(1))*pad ];

vals = repmat( lims(1), size(t) );
vals(is_fix(trial, :) == 1) = lims(2);

inds = find( ~is_fix(trial, :) );

[starts, durs] = shared_utils.logical.find_all_starts( ~is_fix(trial, :) );

for i = 1:numel(starts)
  start = starts(i);
  stop = starts(i) + durs(i) - 1;
  
  plot( [t(start); t(start)], lims, 'k--' );
  plot( [t(stop); t(stop)], lims, 'g--' );
end

%%

use_fix = true;

if ( ~use_fix ), is_fix(:) = true; end

wsize = 10;
ssize = 10;

[runlabs, I] = keepeach( labs', {'unified_filename', 'stim_type', 'roi'} );

p = rowop( double(ib & is_fix), I, @(x) sum(x, 1) / size(x, 1) );

binned_p = [];
binned_t = cellfun( @median, shared_utils.vector.slidebin(t, wsize, ssize, true) );

for i = 1:size(p, 1)
  binned_p(end+1, :) = cellfun( @any, shared_utils.vector.slidebin(p(i, :), wsize, ssize, true) );
end

%%

use_binned = true;

pltdat = ternary( use_binned, binned_p, p );
pltt = ternary( use_binned, binned_t, t );
pltlabs = runlabs';

pl = plotlabeled.make_common();
pl.x = pltt;
pl.y_lims = [0, 1];

mask = fcat.mask( pltlabs, @find, 'eyes_nf' );
gcats = 'stim_type';
pcats = {'roi'};

figure(1);
clf();

axs = pl.lines( pltdat(mask, :), pltlabs(mask), gcats, pcats );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [-0.15, 0] );

%%

