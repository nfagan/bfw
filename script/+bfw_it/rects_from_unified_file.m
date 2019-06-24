function rects = rects_from_unified_file(un_file, kind)

rects = arrayfun( @(x) x.(kind), un_file.m1.trial_data, 'un', 0 );
rects = vertcat( rects{:} );

end