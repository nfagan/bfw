function v = field_or(s, field, val)

%   FIELD_OR -- Get field or default value.
%
%     v = ... field_or( s, FIELD, VALUE ) returns `s.(FIELD)` if `FIELD` is
%     a field of `s`, or else `VALUE`.
%
%     IN:
%       - `s` (struct)
%       - `field` (char)
%       - `val` (/any/)
%     OUT:
%       - `v` (/any/)

v = val;
if ( isfield(s, field) ), v = s.(field); end

end