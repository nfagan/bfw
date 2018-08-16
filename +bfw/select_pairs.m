function pairs = select_pairs(A, B, n)

n_choose = min( [n, numel(A), numel(B)] );

pairs = nan( n_choose, 2 );

for i = 1:n_choose
  [pairs(i, :), A, B] = select( A, B );
end

end

function [pair, A, B] = select(A, B)

IA = randperm( numel(A), 1 );
IB = randperm( numel(B), 1 );

pair = [ A(IA), B(IB) ];
A(IA) = [];
B(IB) = [];

end