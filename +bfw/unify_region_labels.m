function l = unify_region_labels(l)

prune( l );
fix_acc( l );

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

function fix_acc(l)

regs = incat( l, 'region' );
reg_split = cellfun( @(x) strsplit(x, '_'), regs, 'un', 0 );

r = check_acc( reg_split );

for i = 1:numel(regs)
  replace( l, regs{i}, r{i} );
end

end

function r = check_acc(reg_split)

r = cell( size(reg_split) );

for i = 1:numel(r)
  c = reg_split{i};
  is_acc = strcmp( c, 'acc' );
  
  c(is_acc) = { 'accg' };
  r{i} = strjoin( c, '_' );
end

end