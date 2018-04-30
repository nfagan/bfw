function c = num2cat(ns, categ)

c = arrayfun( @(x) sprintf('%s%d', categ, x), ns, 'un', false );

end