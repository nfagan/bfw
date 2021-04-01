function bfw_check_non_overlapping_mutual_exclusive_events(start_inds, stop_inds, labels, mask)

if ( nargin < 4 )
  mask = rowmask( start_inds );
end

assert_ispair( start_inds, labels );
assert_ispair( stop_inds, labels );

run_I = findall( labels, 'unified_filename', mask );

for i = 1:numel(run_I)  
  shared_utils.general.progress( i, numel(run_I) );
  
  mut_ind = find( labels, 'mutual', run_I{i} );
  m1_ind = find( labels, 'm1', run_I{i} );
  m2_ind = find( labels, 'm2', run_I{i} );
  
  m1r = arrayfun( @(x) start_inds(x):stop_inds(x), m1_ind, 'un', 0 );
  m2r = arrayfun( @(x) start_inds(x):stop_inds(x), m2_ind, 'un', 0 );
  mut = arrayfun( @(x) start_inds(x):stop_inds(x), mut_ind, 'un', 0 );
  
  for j = 1:numel(mut)
    for k = 1:numel(m1r)
      overlapm1 = intersect( mut{j}, m1r{k} );
      assert( mut{j}(1) ~= m1r{k}(1), 'm1-mut starts match' );
      assert( isempty(overlapm1), 'm1-mut ranges overlap' );
    end
    for k = 1:numel(m2r)
      overlapm2 = intersect( mut{j}, m2r{k} );
      assert( mut{j}(1) ~= m2r{k}(1), 'm2-mut starts match' );
      assert( isempty(overlapm2), 'm2-mut ranges overlap' );
    end
  end
end

end