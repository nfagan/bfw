n_out = bfw_n_minus_n_events( ...
    'is_parallel', true ...
  , 'minimum_inter_event_interval', -Inf ...
  , 'maximum_inter_event_interval', Inf ...
  , 'allowed_looks_by', {} ...
  , 'n_previous', 1 ...
);

%%  eye mouth face(eye-mouth), nonsocial-object, everything else

%%

labs = n_out.labels';

min_iei = -Inf;
max_iei = 1;
use_interval_thresh = true;

if ( use_interval_thresh )
  mask = find( n_out.intervals > min_iei & n_out.intervals < max_iei );
else
  mask = rowmask( labs );
end

mask = fcat.mask( labs, mask ...
  , @find, {'mouth', 'eyes_nf'} ...
  , @findnone, '<previous_roi>' ...
  , @findnone, {'mutual', 'previous_mutual'} ...
  , @find, {'free_viewing', 'no-stimulation'} ...
  , @find, 'm1' ...
);

props_each = { 'unified_filename', 'looks_by', 'roi' };
props_of = { 'previous_roi', 'previous_looks_by' };

[counts, pltlabs] = proportions_of( labs, props_each, props_of, mask );

%%

pl = plotlabeled.make_common();
% pl.y_lims = [0, 0.5];
pl.x_tick_rotation = 0;
pl.fig = figure(2);

xcats = { 'roi' };
gcats = { 'previous_roi', 'previous_looks_by' };
pcats = { 'looks_by' };

pl.bar( counts, pltlabs, xcats, gcats, pcats );

%%

uselabs = pltlabs';
usedat = counts;

target_roi = 'eyes_nf';

mean_spec = unique( cshorzcat(xcats, gcats, pcats) );

[uselabs, I] = keepeach( uselabs, mean_spec );
usedat = rownanmean( usedat, I );

is_target = find( uselabs, target_roi );
is_prev_eyes = find( uselabs, 'previous_eyes_nf', is_target );
is_prev_mouth = find( uselabs, 'previous_mouth', is_target );

is_prev_m1 = find( uselabs, 'previous_m1', is_target );
is_prev_m2 = find( uselabs, 'previous_m2', is_target );

prev_eyes_m1 = usedat(intersect(is_prev_eyes, is_prev_m1));
prev_mouth_m1 = usedat(intersect(is_prev_mouth, is_prev_m1));
prev_eyes_m2 = usedat(intersect(is_prev_eyes, is_prev_m2));
prev_mouth_m2 = usedat(intersect(is_prev_mouth, is_prev_m2));

X = [ prev_eyes_m1, prev_mouth_m1; prev_eyes_m2, prev_mouth_m2 ];

colormap( 'hot' );
imagesc( X );
colorbar;
ax = gca;

set( ax, 'xtick', 1:2 );
set( ax, 'ytick', 1:2 );

set( ax, 'xticklabel', {'eyes', 'mouth'} );
set( ax, 'yticklabel', {'m1 looked to', 'm2 looked to'} );

title( sprintf('Preceding m1 looks to %s', strrep(target_roi, '_', ' ')) );

%%

uselabs = pltlabs';
usedat = counts;

target_roi = 'eyes_nf';

is_target = find( uselabs, target_roi );
is_prev_eyes = find( uselabs, 'previous_eyes_nf', is_target );
is_prev_mouth = find( uselabs, 'previous_mouth', is_target );

is_prev_m1 = find( uselabs, 'previous_m1', is_target );
is_prev_m2 = find( uselabs, 'previous_m2', is_target );

prev_eyes_m1 = usedat(intersect(is_prev_eyes, is_prev_m1));
prev_mouth_m1 = usedat(intersect(is_prev_mouth, is_prev_m1));
prev_eyes_m2 = usedat(intersect(is_prev_eyes, is_prev_m2));
prev_mouth_m2 = usedat(intersect(is_prev_mouth, is_prev_m2));

prev_rois = { 'previous_eyes_nf', 'previous_mouth' };
prev_looks_by = { 'previous_m1', 'previous_m2' };

C = combvec( 1:numel(prev_rois), 1:numel(prev_looks_by) );
n_c = size( C, 2 );
subplot_shape = shared_utils.plot.get_subplot_shape( n_c );

axs = gobjects( 1, n_c );

for i = 1:n_c
  ax = subplot( subplot_shape(1), subplot_shape(2), i );
  
  current_prev_roi = prev_rois{C(1, i)};
  current_prev_looks_by = prev_looks_by{C(2, i)};
  
  is_subset = find( uselabs, {current_prev_roi, current_prev_looks_by}, is_target );
  subset_dat = usedat(is_subset);
  
  N = numel( subset_dat );
  
  ceil_m = ceil( sqrt(N) );
  floor_m = floor( sqrt(N) );
  
  new_dat = nan( ceil_m );
  new_dat(1:floor_m, 1:floor_m) = reshape( subset_dat(1:(floor_m*floor_m)), floor_m, floor_m );
  
  imagesc( new_dat );
  
  axs(i) = ax;
  
  title_str = sprintf('%s - %s', current_prev_roi, current_prev_looks_by );
  title_str = strrep( title_str, '_', ' ' );
  
  title( title_str );
end

shared_utils.plot.match_clims( axs );





