function keep = bfw_exclusive_events(start_indices, stop_indices, labels, pairs, I)

%   BFW_EXCLUSIVE_EVENTS -- Get indices of non-overlapping events.
%
%     keep = bfw_exclusive_events( start_indices, stop_indices, labels, pairs, I )
%     returns indices of events such that the subset of events identified
%     by those indices contains no overlapping elements.
%
%     `start_indices` and `stop_indices` are equal-length vectors that
%     identify the start and stop index of each event. `labels` is an fcat
%     array with the same number of rows as `start_indices`, giving the roi
%     label (and possibly additional labels) for each event. `pairs` gives
%     a list of pairs of roi (or other) string labels between which events 
%     should be made exclusive. For example, if `pairs` is {{'eyes', 'face'}}, 
%     then events associated with the label 'eyes' and events associated 
%     with the label 'face' that overlap will be removed from the list of 
%     'face' events, retaining the 'eye' events.
%
%     `I` is an optional cell array of indices within which events should
%     be made exclusive, but across which events are not guaranteed to be 
%     made exclusive. For example if `I` is {1:100, 200:300}, then events 
%     will be made exclusive within the first 1:100 rows, and then 
%     separately within rows 200:300, but may overlap between rows 1:100
%     and 200:300.
%
%     See also fcat, fcat/findall, bfw_linearize_events

assert_ispair( start_indices, labels );

if ( nargin < 5 )
  I = { rowmask(labels) };
end

N = numel( start_indices );
validateattributes( stop_indices, {'double'}, {'numel', N}, mfilename, 'stop_indices' );

keep = fast_method( start_indices, stop_indices, labels, pairs, I );

end

function keep = fast_method(start_indices, stop_indices, labels, pairs, I)

keep = true( numel(start_indices), 1 );

for i = 1:numel(I)  
  for j = 1:numel(pairs)
    is_a = find( labels, pairs{j}{1}, I{i} );
    is_b = find( labels, pairs{j}{2}, I{i} );
    
    start_a = start_indices(is_a);
    stop_a = stop_indices(is_a);
    
    for k = 1:numel(is_b)
      c_is_b = is_b(k);
      
      start_b = start_indices(c_is_b);
      stop_b = stop_indices(c_is_b);
      
      pre_a_start =   any( start_b <= start_a & stop_b >= start_a );
      pre_a_stop =    any( start_b <= stop_a & stop_b >= stop_a );
      is_eq_start =   any( (start_b == start_a) | (start_b == stop_a) );
      is_eq_stop =    any( (stop_b == start_a) | (stop_b == stop_a) );
      within_range =  any( start_b >= start_a & stop_b <= stop_a );
      
      overlaps_with_a = pre_a_start || pre_a_stop || is_eq_start || ...
        is_eq_stop || within_range;
      
      if ( overlaps_with_a )
        keep(c_is_b) = false;
      end
    end
  end
end

keep = find( keep );

end

function keep = slow_method(start_indices, stop_indices, labels, pairs, I)

keep = true( numel(start_indices), 1 );

for i = 1:numel(I)  
  shared_utils.general.progress( i, numel(I) );
  
  for j = 1:numel(pairs)
    is_a = find( labels, pairs{j}{1}, I{i} );
    is_b = find( labels, pairs{j}{2}, I{i} );
    
    range_a = arrayfun( @(x, y) x:y, start_indices(is_a), stop_indices(is_a), 'un', 0 );
    
    for k = 1:numel(is_b)
      c_is_b = is_b(k);
      
      start_b = start_indices(c_is_b);
      stop_b = stop_indices(c_is_b);
      
      range_b = start_b:stop_b;
      overlaps_with_a = cellfun( @(x) ~isempty(intersect(x, range_b)), range_a );
      
      if ( any(overlaps_with_a) )
        keep(c_is_b) = false;
      end
    end
  end
end

keep = find( keep );


end