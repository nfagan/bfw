function [inds, labs] = find_shared_unit_ids(gaze_labels, rwd_labels ...
  , gaze_mask_func, rwd_mask_func)

if ( nargin < 3 )
  gaze_mask_func = @bfw.default_mask_func;
end
if ( nargin < 4 )
  rwd_mask_func = @bfw.default_mask_func;
end

shared_ids = bfw_lda.shared_unit_ids( gaze_labels, rwd_labels );
num_units = size( shared_ids, 2 );

gaze_base_mask = get_gaze_base_mask( gaze_labels, gaze_mask_func );
rwd_base_mask = get_rwd_base_mask( rwd_labels, rwd_mask_func );

inds = {};
labs = fcat();

for i = 1:num_units
  unit_selectors = shared_ids(:, i);
  
  gaze_ind = find( gaze_labels, unit_selectors, gaze_base_mask );
  rwd_ind = find( rwd_labels, unit_selectors, rwd_base_mask );
  
  if ( isempty(gaze_ind) || isempty(rwd_ind) )
    continue;
  end
  
  inds{end+1} = { gaze_ind, rwd_ind };
  
  gaze_labs = append1( fcat, gaze_labels, gaze_ind );
  rwd_labs = append1( fcat, rwd_labels, rwd_ind );
  
  join( gaze_labs, rwd_labs );
  append( labs, gaze_labs );
end

end

function mask = get_gaze_base_mask(labels, func)

gaze_base_mask = rowmask( labels );
mask = func( labels, gaze_base_mask );

end

function mask = get_rwd_base_mask(labels, func)

rwd_base_mask = fcat.mask( labels ...
  , @findnone, 'reward-NaN' ...
);

mask = func( labels, rwd_base_mask );

end