function lda = bfw_load_mult_cs_lda_data(lda_files, varargin)

lda_files = cellstr( lda_files );

lda = [];

for i = 1:numel(lda_files)
  tmp_lda = bfw_load_cs_lda_data( lda_files{i}, varargin{:} );
  
  if ( isempty(lda) )
    lda = tmp_lda;
    lda.params = { tmp_lda.params };
    lda.param_indices = ones( rows(lda.labels), 1 );
    continue;
  end
  
  current_rois = combs( lda.labels, 'roi' );
  incoming_rois = combs( tmp_lda.labels, 'roi' );
  
  new_rois = setdiff( incoming_rois, current_rois );
  
  new_roi_ind = find( tmp_lda.labels, new_rois );
  
  if ( isempty(new_roi_ind) )
    continue;
  end
  
  param_inds = repmat( numel(lda.params) + 1, numel(new_roi_ind), 1 );
  
  append( lda.labels, tmp_lda.labels, new_roi_ind );
  lda.performance = [ lda.performance; tmp_lda.performance(new_roi_ind, :) ];
  lda.params{end+1} = tmp_lda.params;
  lda.param_indices = [ lda.param_indices; param_inds ];
end

end