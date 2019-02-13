function keep = bfw_exclusiveize_events(start_indices, stop_indices, labels, rois, I)

assert_ispair( start_indices, labels );
validateattributes( stop_indices, {'double'}, {'vector', 'numel', numel(start_indices)} ...
  , mfilename, 'stop_indices' );

keep = cell( numel(I), 1 );

for i = 1:numel(I)
  current_I = I{i};
  keep_I = true( numel(current_I), 1 );
  
  for j = 1:numel(rois)
    for k = j:numel(rois)
      if ( j == k ), continue; end
      
      roi1_I = find( labels, rois{j}, current_I(keep_I) );
      roi2_I = find( labels, rois{k}, current_I(keep_I) );

      start_indices1 = start_indices(roi1_I);
      stop_indices1 = stop_indices(roi1_I);

      start_indices2 = start_indices(roi2_I);
      stop_indices2 = stop_indices(roi2_I);

      for h = 1:numel(start_indices2)
        start = start_indices2(h);
        stop = stop_indices2(h);
        
        % (start B >= start A) & (stop A >= start B)
        condition1 = start >= start_indices1 & stop_indices1 >= stop;
        
        % (start A >= start B) & (stop B >= start A)
        condition2 = start_indices1 >= start & stop >= start_indices1;
        
        events_overlap = condition1 | condition2;
        
        if ( any(events_overlap) )
          keep_I(roi2_I(h)) = false;
        end
      end
    end
  end
  
  keep{i} = current_I(keep_I);
end

keep = vertcat( keep{:} );

end