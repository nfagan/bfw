conf = bfw.config.load();

conf.PATHS.data_root = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/free_viewing';

look_ahead = 5;
look_back = -1;
roi_pad = 0;

[outs, t, params] = debug_stim_times( ...
    'config',     conf ...
  , 'look_ahead', look_ahead ...
  , 'look_back',  look_back ...
  , 'roi_pad',    roi_pad ...
);

%%

try 
  labs = prune( bfw.get_region_labels(outs.labs') );
catch err
  %   we're missing a region specifier for a given session, so region
  %   labels are unreliable.
  labs = collapsecat( outs.labs', 'region' );
end

ib = outs.ib;
is_fix = outs.is_fix;
x = outs.x;
y = outs.y;

%%  make bounds

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

%%  plot bounds

use_binned = true;

pltdat = ternary( use_binned, double(binned_p), p );
pltt = ternary( use_binned, binned_t, t );
pltlabs = runlabs';

pl = plotlabeled.make_common();
pl.x = pltt;
pl.y_lims = [0, 1];
pl.add_smoothing = true;
pl.smooth_func = @(x) smooth(x, 5);

mask = fcat.mask( pltlabs, @find, {'eyes_nf'} );
gcats = { 'stim_type' };
pcats = { 'roi', 'region' };

figure(1);
clf();

axs = pl.lines( pltdat(mask, :), pltlabs(mask), gcats, pcats );
shared_utils.plot.hold( axs, 'on' );
shared_utils.plot.add_vertical_lines( axs, [-0.15, 0] );

%%  find events

import shared_utils.vector.slidebin;

use_binned = true;
min_length = 10;

evt_ib = ib & is_fix;

h = waitbar( 0 );

if ( use_binned )
  tmp_evt_p = logical([]);
  
  for i = 1:rows(evt_ib)
    waitbar( i/rows(evt_ib), h, 'binning ...' );
    
    tmp_evt_p(i, :) = cellfun( @any, slidebin(evt_ib(i, :), wsize, ssize, true) );
  end
  
  evt_ib = tmp_evt_p;
  evt_t = cellfun( @(x) x(1), slidebin(t, wsize, ssize, true) );
else
  evt_t = t;
end

use_labs = labs';

fixdur = [];
durlabs = fcat();

nfix = rowzeros( rows(evt_ib) );
totaldur = rowzeros( rows(evt_ib) );
fixlabs = fcat();

for i = 1:rows(evt_ib)
  waitbar( i/rows(evt_ib), h, 'finding starts ...' );
  
  [dat, startlabs] = bfw.find_labeled_starts( evt_ib(i, :), use_labs(i) );
  
  is_long_enough = dat(:, 2) >= min_length;
    
  dat(:, 1) = evt_t(dat(:, 1));
  
  current_nfix = sum( is_long_enough );
  current_total_duration = sum( dat(is_long_enough, 2) );
  
  fixdur = [ fixdur; dat ];
  append( durlabs, startlabs );
  
  nfix(i) = current_nfix;
  totaldur(i) = current_total_duration;
  append( fixlabs, use_labs, i );
end

assert_ispair( fixdur, durlabs );
assert_ispair( nfix, fixlabs );

addsetcat( fixlabs, 'data_type', 'nfix' );
addsetcat( durlabs, 'data_type', 'fix_duration' );
total_durlabs = setcat( fixlabs', 'data_type', 'total_duration' );

close( h );
%%  

is_post0 = fixdur(:, 1) >= 0;
is_long_enough = fixdur(:, 2) > 30;

select = is_post0 & is_long_enough;

combined_dat = [ fixdur(select, 2); nfix; totaldur ];
combined_labs = extend( durlabs(find(select)), fixlabs, total_durlabs );

%%  box plot

pltdat = combined_dat;
pltlabs = combined_labs';

pl = plotlabeled.make_common();

mask = fcat.mask( pltlabs, @find, {'total_duration', 'eyes_nf'} );

gcats = { 'stim_type', 'data_type' };
pcats = { 'roi', 'task_type', 'region' };

figure(1);
clf();

axs = pl.boxplot( pltdat(mask), pltlabs(mask), gcats, pcats );

%%  bar plot

% pltdat = fixdur(select, 2);
% pltlabs = durlabs(find(select));

pltdat = combined_dat;
pltlabs = combined_labs';

pl = plotlabeled.make_common();
pl.add_points = false;
pl.marker_size = 4;
pl.marker_type = '+';
pl.add_points = false;
pl.x_tick_rotation = 0;
pl.group_order = { 'stim', 'sham' };

mask = fcat.mask( pltlabs, @find, {'eyes_nf', 'total_duration'} );

xcats = { 'task_type', 'data_type' };
gcats = { 'stim_type' };
pcats = { 'roi', 'region' };

figure(1);
clf();

axs = pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );

%%  hists

pltdat = combined_dat;
pltlabs = combined_labs';

pl = plotlabeled.make_common();
pl.add_points = false;
pl.marker_size = 4;
pl.marker_type = '+';

mask = fcat.mask( pltlabs, @find, {'nfix', 'eyes_nf', 'accg'} );

pcats = { 'roi', 'stim_type', 'task_type', 'region', 'data_type' };

figure(1);
clf();

masked_dat = pltdat(mask);
masked_labs = pltlabs(mask);

[axs, indices] = pl.hist( masked_dat, masked_labs, pcats, 100 );
shared_utils.plot.hold( axs, 'on' );

meds = rowop( masked_dat, indices, @(x) median(x, 1) );
arrayfun( @(x, y) plot(x, [y; y], get(x, 'ylim'), 'k--'), axs, meds );

%%  rank sum

usedat = combined_dat;
uselabs = combined_labs';

spec = { 'region', 'roi', 'task_type', 'data_type' };

mask = fcat.mask( uselabs, @find, {'eyes_nf'} );

rs_outs = dsp3.ranksum( usedat, uselabs', spec, 'sham', 'stim', 'mask', mask );

rs_tables = vertcat( rs_outs.rs_tables{:} );
rs_labels = rs_outs.rs_labels';

rmcat( rs_labels, getcats(rs_labels, 'un') );
rs_tables.Properties.RowNames = fcat.strjoin( cellstr(rs_labels)', ' | ' )';


