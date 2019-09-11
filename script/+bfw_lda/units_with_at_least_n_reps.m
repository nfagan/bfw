function [unit_C, removed_C, kept_I] = units_with_at_least_n_reps(counts, labels, each, reps_of, or_each, num_reps, mask)

assert_ispair( counts, labels );

if ( nargin < 7 )
  mask = rowmask( labels );
end

[I, each_C] = findall( labels, each, mask );
C = combs( labels, reps_of, mask );

to_keep = true( size(I) );

for i = 1:numel(I)  
  or_I = findall( labels, or_each, I{i} );
  
  can_keep = true( size(or_I) );
  
  for j = 1:numel(or_I)
    for k = 1:size(C, 2)
      ind = find( labels, C(:, k), or_I{j} );
      did_fire = any( counts(ind, :) > 0, 2 );

      if ( nnz(did_fire) < num_reps )
        can_keep(j) = false;
        break;
      end
    end
  end
  
  to_keep(i) = any( can_keep );
end

unit_C = each_C(:, to_keep);
removed_C = each_C(:, ~to_keep);
kept_I = vertcat( I{to_keep} );

end