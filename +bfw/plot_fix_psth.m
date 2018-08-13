function plot_fix_psth(ax, time, position, events, lb, la, rect, colorfunc)

position = check_pos_size( position );

assert( numel(time) == size(position, 2), 'Time must match position.' );
assert( numel(rect) == 4, 'Specify rect as a 4-element vector.' );

for i = 1:numel(events)
  evt = events(i);
  
  set( ax, 'nextplot', 'add' );
  
  pre_ind = time >= evt + lb & time < evt;
  post_ind = time >= evt & time < evt + la;
  
  h1 = plot1( ax, position, pre_ind | post_ind, colorfunc, false );
end

shared_utils.plot.rect( rect, ax );

end

function h = plot1(ax, position, ind, colorfunc, flip)

n_pts = sum( ind );

colors = colorfunc( n_pts );

if ( n_pts > 0 )
  sz = 4;
  szs = repmat( sz, 1, n_pts );
  szs(1) = 100;
  colors(1, :) = 0;
else
  szs = [];
end

if ( flip ), colors = flipud( colors ); end
h = scatter( ax, position(1, ind), position(2, ind), szs, colors );

end

function pos = check_pos_size(pos)
s = size( pos );
if ( s(2) == 2 ), pos = pos'; end
end