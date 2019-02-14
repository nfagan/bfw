function keep = bfw_exclusiveize_events(start_indices, stop_indices, labels, rois, I, check_remove)

%   BFW_EXCLUSIVEIZE_EVENTS -- Ensure events are non-overlapping.
%
%     exclusive_indices = ...
%       bfw_exclusiveize_events(start_indices, stop_indices, labels, rois, I);
%
%     returns indices of events that do not overlap in time. That is, each
%     element in `exclusive_indices` identifies a tuple of (start, stop)
%     indices that do not overlap with other tuples of (start, stop) indices.
%
%     `start_indices` is a vector of start times or indices representing
%     the onset of each event. `stop_indices` is a vector of stop times or
%     indices representing the end of each event. `labels` is an fcat array
%     with the same number of rows as `start_indices` giving the roi label
%     (and possibly other information) for each event. `rois` is a cell
%     array of strings giving the names of rois over which to make
%     exclusive. `I` is a cell array of indices; events are made exclusive
%     only within each subset of rows identified by each index vector in
%     `I`. `I` can also be the empty double array ([]), indicating that
%     events will be made exclusive across all rows of `start_indices`.
%
%     bfw_exclusiveize_events( ..., check_remove ) calls the user-supplied 
%     function`check_remove` to determine whether overlapping events should be
%     removed from `exclusive_indices`. The form of `check_remove` is
%     as follows: tf = check_remove( roi1, roi2 ), where `roi1` and
%     `roi2` are the names of the rois that overlap, should return true if 
%     the event time associated with `roi2` is to be be removed from 
%     `exclusive_indices`, and false otherwise. You can specify this 
%     function to e.g. only remove events if roi1 is 'eyes' and roi2 is 'face'.
%
%     See also fcat, bfw.make.raw_events

if ( nargin < 5 || isequal(I, []) )
  I = { rowmask(stop_indices) };
end

if ( nargin < 6 )
  check_remove = @(varargin) true;  % always remove
end

assert_ispair( start_indices, labels );

validateattributes( stop_indices, {'double'}, {'vector', 'numel' ...
  , numel(start_indices)}, mfilename, 'stop_indices' );

validateattributes( check_remove, {'function_handle'}, {'scalar'} ...
  , mfilename, 'check_remove' );

keep = true( numel(start_indices), 1 );

roi_vec = [ 1:numel(rois), fliplr(1:numel(rois)) ];

for i = 1:numel(I)
  current_I = I{i};
  
  for j = 1:numel(roi_vec)
    for k = j:numel(roi_vec)
      roi1_ind = roi_vec(j);
      roi2_ind = roi_vec(k);
      
      if ( roi1_ind == roi2_ind ), continue; end
      
      roi1 = rois{roi1_ind};
      roi2 = rois{roi2_ind};
      
      roi1_I = find( labels, roi1, current_I );
      roi2_I = find( labels, roi2, current_I );

      start_indices1 = start_indices(roi1_I);
      stop_indices1 = stop_indices(roi1_I);

      start_indices2 = start_indices(roi2_I);
      stop_indices2 = stop_indices(roi2_I);

      for h = 1:numel(start_indices2)
        start = start_indices2(h);
        stop = stop_indices2(h);
        
        % start B == start A | stop B == stop A
        condition1 = start == start_indices1 | stop == stop_indices1;
        
        % (start B >= start A) & (stop A >= start B)
        condition2 = start >= start_indices1 & stop_indices1 >= stop;
        
        % (start A >= start B) & (stop B >= start A)
        condition3 = start_indices1 >= start & stop >= start_indices1;
        
        events_overlap = condition1 | condition2 | condition3;
        
        if ( any(events_overlap) && check_remove(roi1, roi2) )
          keep(roi2_I(h)) = false;
        end
      end
    end
  end
end

keep = find( keep );

end