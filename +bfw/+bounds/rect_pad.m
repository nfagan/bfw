function rect = rect_pad(rect, padx, pady)

%   RECT_PAD -- Apply padding to rect.
%
%     r = ... rect_pad( r, x, y ); pads the 4-element rect vector given by
%     `r` with scalar values `x` and `y`.
%
%     IN:
%       - `rect` (double)
%       - `padx` (double) |SCALAR|
%       - `pady` (double) |SCALAR|
%     OUT:
%       - `r` (double)

rect(1) = rect(1) - padx;
rect(3) = rect(3) + padx;
rect(2) = rect(2) - pady;
rect(4) = rect(4) + pady;

end