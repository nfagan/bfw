function debug_check_oob_stim(varargin)

defaults = struct();
defaults.labels = fcat();
defaults.t = [];
defaults.trange = [ -0.01, 0.01 ];
defaults.traces = [];
defaults.rois = [];
defaults.x = [];
defaults.y = [];
defaults.mask = 'off';

params = bfw.parsestruct( defaults, varargin );

labs = params.labels';
t = params.t;
trange = params.trange;
x = params.x;
y = params.y;
traces = params.traces;
rois = params.rois;

assert_ispair( traces, labs );
assert_rowsmatch( traces, rois );
assert_rowsmatch( traces, x );
assert_rowsmatch( x, y );
assert( numel(t) == size(traces, 2), 'Time does not correspond to traces.' );

if ( ischar(params.mask) && strcmp(params.mask, 'off') )
  mask = rowmask( labs );
else
  mask = params.mask;
end

t0_ind = t >= trange(1) & t <= trange(2);
is_oob = ~any( traces(:, t0_ind), 2 );

oob_masked = intersect( mask, find(is_oob) );
ib_masked = intersect( mask, find(~is_oob) );

%%

f = figure(1);
clf( f );

oob_ind = oob_masked(randi(numel(oob_masked)));
% oob_ind = ib_masked(randi(numel(ib_masked)));
t_ind = t >= -1 & t <= 2;

c = hot( nnz(t_ind) );

ax = gca;
shared_utils.plot.rect( rois(oob_ind, :), ax );
shared_utils.plot.hold( ax, 'on' );

h_dots = scatter( columnize(x(oob_ind, t_ind)), columnize(y(oob_ind, t_ind)), 1, c );
h_bar = colorbar();
colormap( h_bar, c );
caxis( [min(t(t_ind)), max(t(t_ind))] );

n_first = min( 10, nnz(t_ind) );
f_t_ind = find( t_ind );

h_first = plot( x(oob_ind, f_t_ind(1:n_first)), y(oob_ind, f_t_ind(1:n_first)), 'k*', 'markersize', 15 );
set( h_first, 'color', c(1, :) );

plot( x(oob_ind, t0_ind), y(oob_ind, t0_ind), 'go', 'markersize', 25 );

un_filename = combs( labs, 'unified_filename', oob_ind );
roi_file = bfw.load1( 'rois', un_filename );
h = shared_utils.plot.rect( roi_file.m1.rects('eyes_nf'), ax );
set( h, 'edgecolor', 'r' );
h2 = shared_utils.plot.rect( roi_file.m1.rects('face'), ax );


end