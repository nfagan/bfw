function l = unify_coherence_region_labels(l)

regs = incat( l, 'region' );
reg_split = cellfun( @(x) strsplit(x, '_'), regs, 'un', 0 );

is_unifyable = cellfun( @numel, reg_split ) == 2;

if ( ~any(is_unifyable) )
  return;
end

regs(~is_unifyable) = [];
reg_split(~is_unifyable) = [];

replace_with = cellfun( @(x) strjoin(sort(x), '_'), reg_split, 'un', 0 );

for i = 1:numel(regs)
  replace( l, regs{i}, replace_with{i} );
end

end