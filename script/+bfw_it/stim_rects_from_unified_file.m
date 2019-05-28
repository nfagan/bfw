function stim_rects = stim_rects_from_unified_file(un_file)

stim_rects = arrayfun( @(x) x.stim_rect, un_file.m1.trial_data, 'un', 0 );
stim_rects = vertcat( stim_rects{:} );

end