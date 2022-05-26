function [ii, off] = clamp_range(i, lo, hi)

if ( i < lo )
  ii = lo;
  off = lo - i;
elseif ( i > hi )
  ii = hi;
  off = i - hi;
else
  ii = i;
  off = 0;
end

end