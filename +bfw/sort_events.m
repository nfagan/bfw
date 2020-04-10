function sorted_events = sort_events(events, each, mask)

if ( nargin < 2 )
  each = { 'unified_filename' };
end

if ( nargin < 3 )
  mask = rowmask( events.labels );
end

times = bfw.event_column( events, 'start_time' );
each_I = findall_or_one( events.labels, each, mask );
tot_order = rowmask( times );

for i = 1:numel(each_I)
  [~, order] = sort( times(each_I{i}) );
  tot_order(each_I{i}) = tot_order(each_I{i}(order));
end

sorted_events = bfw.keep_events( events, tot_order, true );

end