function events_file_out = make_non_overlapping_events_file(events_file, rois, non_overlapping_pairs, each, mask)

event_labels = fcat.from( events_file );

if ( nargin < 4 )
  each = {};
end

if ( nargin < 5 )
  mask = rowmask( event_labels );
end

if ( ~isempty(rois) )
  mask = findor( event_labels, rois, mask );
end

[non_overlapping_indices, each_I] = ...
  get_non_overlapping_event_indices( events_file, non_overlapping_pairs, rois, each, mask );
events_file_out = keep_events( events_file, mask );

for i = 1:numel(each_I)  
  non_overlapping_mask = intersect( each_I{i}, non_overlapping_indices );
  
  for j = 1:numel(non_overlapping_pairs)
    pair = non_overlapping_pairs{j};
    exclusive_second_ind = find( event_labels, pair{2}, non_overlapping_mask );
    roi_str = sprintf( '%s_non_%s', pair{2}, pair{1} );
    
    exclusive_second_events = events_file.events(exclusive_second_ind, :);
    exclusive_second_labels = events_file.labels(exclusive_second_ind, :);
    [~, roi_category_ind] = ismember( 'roi', events_file.categories );
    exclusive_second_labels(:, roi_category_ind) = { roi_str };
    
    events_file_out.events = [ events_file_out.events; exclusive_second_events ];
    events_file_out.labels = [ events_file_out.labels; exclusive_second_labels ];
  end
end

end

function [non_overlapping, each_I] = get_non_overlapping_event_indices(events_file, pairs, rois, each, mask)

if ( ~isempty(rois) )
  is_pair_with_roi = cellfun( @(x) all(ismember(x, rois)), pairs );
  pairs = pairs(is_pair_with_roi);
end

[non_overlapping, each_I] = bfw_exclusive_events_from_events_file( events_file, pairs, each, mask );
non_nan = bfw_non_nan_linearized_event_times( events_file );

non_overlapping = intersect( non_overlapping, non_nan );
non_overlapping = intersect( non_overlapping, mask );

end

function events_file_out = keep_events(events_file, ind)

events_file_out = events_file;
events_file_out.events = events_file.events(ind, :);
events_file_out.labels = events_file.labels(ind, :);

end