function [data, was_ref_subtracted, ref_ind] = ref_subtract_fcat(data, labels, event_indices)

was_ref_subtracted = false;

reflab = 'ref';

ref_I = findall( labels, 'region', find(labels, reflab) );
rest_I = findall( labels, {'region', 'channel'}, findnone(labels, reflab) );

if ( isempty(ref_I) || isempty(rest_I) ), return; end

ref_ind = ref_I{1};

for i = 1:numel(rest_I)
  reg_ind = rest_I{i};
  
  if ( nargin > 2 )
    assert( isequal(event_indices(ref_ind), event_indices(reg_ind)) ...
      , 'Event indices did not match between regions.' );
  else
    assert( numel(ref_ind) == numel(reg_ind) ...
      , 'Mismatch in trials for target region and reference.' );
  end
  
  ref_data = data(ref_ind, :);
  reg_data = data(reg_ind, :);
  
  data(reg_ind, :) = reg_data - ref_data;
end

was_ref_subtracted = true;

end