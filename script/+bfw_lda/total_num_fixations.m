function [nfix, nfix_labels] = total_num_fixations(events_file, each, mask)

if ( nargin < 3 )
  mask = rowmask( events_file.labels );
end

each_I = findall( events_file.labels, each, mask );

nfix_labels = cell( size(each_I) );
nfix = cell( size(each_I) );

event_labels = events_file.labels';

for i = 1:numel(each_I)
  roi_I = findall( event_labels, {'roi', 'looks_by', 'event_type'}, each_I{i} );
  
  tmp_labels = fcat();
  for j = 1:numel(roi_I)
    append1( tmp_labels, event_labels, roi_I{j} );
  end
  
  nfix{i} = cellfun( @numel, roi_I );
  nfix_labels{i} = tmp_labels;
end

nfix = vertcat( nfix{:} );
nfix_labels = vertcat( fcat(), nfix_labels{:} );

assert_ispair( nfix, nfix_labels );

end