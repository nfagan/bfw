function [ib, n_include_x, n_include_y, n_included_samples] = rect_excluding_blinks( x, y, rect, blink_threshold )

%   RECT_EXCLUDING_BLINKS -- Adjust rect bounds accounting for blinks.
%
%     IN:
%       - `x` (double)
%       - `y` (double)
%       - `rect` (double) -- 4-element vector
%       - `blink_threshold` (double) -- Maximum number of samples to adjust
%         for blinks.
%     OUT:
%       - `ib` (logical)
%       - `n_included` (double) -- Number of NaN sequences that are
%         adjusted 
%       - `n_included_samples` (double) -- Number of in bounds coordinates
%         included vs. not excluding blinks

m_ib_x = double( bfw.bounds.rect_x_y(x, rect(1), rect(3)) );
m_ib_y = double( bfw.bounds.rect_x_y(y, rect(2), rect(4)) );

m_ib_x( isnan(x) ) = NaN;
m_ib_y( isnan(y) ) = NaN;

[m_ib_x, n_include_x] = remove_blink_nans( m_ib_x, blink_threshold );
[m_ib_y, n_include_y] = remove_blink_nans( m_ib_y, blink_threshold );

ib = m_ib_x & m_ib_y;

other_ib = bfw.bounds.rect( x, y, rect );

% n_included = max( n_include_x, n_include_y );
n_included_samples = sum(ib) - sum(other_ib);

end

function [logical_bounds, n_incl] = remove_blink_nans( bounds, threshold )

shared_utils.assertions.assert__isa( bounds, 'double' );

[nan_starts, nan_lengths] = shared_utils.logical.find_all_starts( isnan(bounds) );

ind = nan_lengths <= threshold;

nan_starts = nan_starts(ind);
nan_lengths = nan_lengths(ind);

n_incl = 0;

for i = 1:numel(nan_starts)
  nan_start = nan_starts(i);
  nan_length = nan_lengths(i);
  
  prev = nan_start - 1;
  post = nan_start + nan_length;
  
  if ( prev < 1 || post > numel(bounds) )
    continue;
  end
  
  if ( bounds(prev) && bounds(post) )
    n_incl = n_incl + 1;
    bounds(nan_start:nan_start+nan_length-1) = 1;
  end
end

logical_bounds = bounds == 1;

end