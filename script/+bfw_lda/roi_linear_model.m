function outs = roi_linear_model(data, categories, order)

validateattributes( data, {'double'}, {'vector'}, mfilename, 'data' );
assert( isequal(size(data), size(categories)) ...
  , 'Expected size of data to match size of labels.' );

num_order = categorical_order_to_numeric_order( categories, order );

lm = fitlm( num_order, data );

outs = struct();
outs.model = lm;
outs.betas = lm.Coefficients.Estimate;
outs.beta_ps = lm.Coefficients.pValue;
outs.roi_beta = lm.Coefficients.Estimate(2);
outs.roi_beta_p = lm.Coefficients.pValue(2);

end

function num_order = categorical_order_to_numeric_order(categories, order)

num_order = nan( size(categories) );

for i = 1:numel(order)
  match_ind = categories == order(i);
  num_order(match_ind) = i;
end

end