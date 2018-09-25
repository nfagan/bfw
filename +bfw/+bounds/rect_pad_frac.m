function rect = rect_pad_frac(rect, fracx, fracy)

%   RECT_PAD -- Apply fractional padding to rect.
%
%     r = ... rect_pad_frac( r, x, y ); pads the 4-element rect vector 
%     given by `r` with horizontal padding that is the fraction `x` of the
%     width in `r`, and with vertical padding that is the fraction `y` of 
%     the height in `r`.
%
%     IN:
%       - `rect` (double)
%       - `padx` (double) |SCALAR|
%       - `pady` (double) |SCALAR|
%     OUT:
%       - `r` (double)

pad_func = @bfw.bounds.rect_pad;

w = rect(3) - rect(1);
h = rect(4) - rect(2);

padx = w * fracx;
pady = h * fracy;

rect = pad_func( rect, padx, pady );

end