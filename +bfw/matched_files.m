function ps = matched_files(src_ps, varargin)

[ps, matched] = bfw.match_files( src_ps, varargin{:} );
ps = ps(all(matched, 2), :);

end