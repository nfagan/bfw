function b = a2b(a, ref_a, ref_b)

%   A2B -- Express `a` in terms of `b`'s units.
%
%     b = ... a2b( a, ref_a, ref_b ) expresses argument `a` in the units of
%     `b`, using a reference quantity that is the same magnitude between 
%     `ref_a` and `ref_b`, but in different units.
%
%     IN:
%       - `a` (double)
%       - `ref_a` (double)
%       - `ref_b` (double)
%     OUT:
%       - `b` (double)

validateattributes( ref_a, {'double'}, {'scalar'}, 'a2b', 'ref_a' );
validateattributes( ref_b, {'double'}, {'scalar'}, 'a2b', 'ref_b' );

b = a .* (ref_b ./ ref_a);

end