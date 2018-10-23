function h = plot_fixation_vector_map(data, data_key, labels, varargin)

assert_ispair( data, labels );

defaults = struct();
defaults.mask = rowmask( data );
defaults.axes = gca;
defaults.thresh_func = @default_thresh_func;

params = bfw.parsestruct( defaults, varargin );
mask = params.mask;

masked = trueat( labels, mask );
assert( max(masked) <= rows(labels), 'Mask is out of bounds of given labels.' );

is_ok = masked & ~cellfun( @isempty, data(:, 1) );

usedat = data(is_ok, :);
uselabs = labels(find(is_ok));

t = usedat(:, data_key('t'));
pos = usedat(:, data_key('position'));

[t, ns] = flatten( t );
pos = flatten( pos );
labs = flatten_labels( uselabs, ns );

I = findall( labs, 'uuid' );

h = gobjects( size(I) );
ax = params.axes;

if ( isempty(I) )
  return
end

x0 = pos(1:2:end, 1);
y0 = pos(2:2:end, 1);
x1 = pos(1:2:end, 2);
y1 = pos(2:2:end, 2);

t_diff = t(:, 2) - t(:, 1);

u = (x1 - x0) ./ t_diff;
v = (y1 - y0) ./ t_diff;

for i = 1:numel(I)
  ind = I{i};
  
  x = x0(ind);
  y = y0(ind);
  u_ = u(ind);
  v_ = v(ind);
  t_ = t(ind);
  
  is_within = params.thresh_func( u_, v_ );
  
  x = x(is_within);
  y = y(is_within);
  u_ = u_(is_within);
  v_ = v_(is_within);
  
  t_= t_(is_within);
  [~, sorted_I] = sort( t_ );
  
  hsv_map = gray( numel(sorted_I) );
  
%   for j = 1:numel(x)
%     idx = sorted_I(j);    
%     
%     one_h = quiver( ax, x(idx), y(idx), u_(idx), v_(idx) );
%     shared_utils.plot.hold( ax, 'on' );
%     
%     one_h.Color = hsv_map(idx, :);
%     one_h.Marker = 'o';
%   end
  
  h(i) = quiver( ax, x, y, u_, v_ );
  
  color_arrows( h(i), hsv_map );
  
  shared_utils.plot.hold( ax, 'on' );
end

end

function color_arrows(q, cmap2)

mags = sqrt(sum(cat(2, q.UData(:), q.VData(:), ...
            reshape(q.WData, numel(q.UData), [])).^2, 2));

%// Get the current colormap
currentColormap = gray();

%// Now determine the color to make each arrow using a colormap
[~, ~, ind] = histcounts(mags, size(currentColormap, 1));

%// Now map this to a colormap to get RGB
cmap = uint8(ind2rgb(ind(:), currentColormap) * 255);
cmap(:,:,4) = 255;
cmap = permute(repmat(cmap, [1 3 1]), [2 1 3]);

base_cmap = uint8( cmap2 * 255 );

% cmap = uint8(ind2rgb(1:rows(cmap2), cmap2) * 255);
% cmap(:,:,4) = 255;
% 
% cmap = permute(repmat(cmap, [1 3 1]), [2 1 3]);

%// We repeat each color 3 times (using 1:3 below) because each arrow has 3 vertices
set(q.Head, ...
    'ColorBinding', 'interpolated', ...
    'ColorData', reshape(cmap(1:3,:,:), [], 4).');   %'

%// We repeat each color 2 times (using 1:2 below) because each tail has 2 vertices
set(q.Tail, ...
    'ColorBinding', 'interpolated', ...
    'ColorData', reshape(cmap(1:2,:,:), [], 4).');

end

function is_within = default_thresh_func(u_, v_)

absu = abs( u_ );
absv = abs( v_ );

summary_u = nanmean( absu );
summary_v = nanmean( absv );

std_u = nanstd( absu );
std_v = nanstd( absv );

is_within_u = absu < (summary_u + std_u * 1.5);
is_within_v = absv < (summary_v + std_v * 1.5);

is_within = is_within_u & is_within_v;

end

function labels = flatten_labels(labs, ns)

assert_ispair( ns, labs );

labels = fcat();

for i = 1:numel(ns)
  append1( labels, labs, i, ns(i) );
end

end

function [data, ns] = flatten(dat)

ns = cellfun( @numel, dat );

data = cellfun( @(x) vertcat(x{:}), dat, 'un', 0 );
data = vertcat( data{:} );

end