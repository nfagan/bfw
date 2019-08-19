function [all_deltas, all_labels] = trial_wise_stim_type_difference(data, labels, each, mask, sfunc)

if ( nargin < 4 )
  mask = rowmask( labels );
end

if ( nargin < 5 )
  sfunc = @(x) nanmean(x, 1);
end

assert_ispair( data, labels );

each_I = findall( labels, each, mask );

all_deltas = [];
all_labels = fcat();

for i = 1:numel(each_I)
  shared_utils.general.progress( i, numel(each_I) );
  
  [trial_I, trial_C] = findall( labels, {'stim_id', 'stim_order'}, each_I{i} );
  
  orders = fcat.parse( trial_C(2, :), 'stim_order__' );
  [sorted_orders, order_I] = sort( orders );
  trial_I = trial_I(order_I);
  trial_C = trial_C(:, order_I);
  
  for j = 1:numel(sorted_orders)-1
    curr_order = sorted_orders(j);
    next_order_ind = find( sorted_orders == curr_order + 1 );
    
    if ( ~isempty(next_order_ind) )
      curr_values = sfunc( rowref(data, trial_I{j}) );
      next_values = sfunc( rowref(data, trial_I{next_order_ind}) );
      
      deltas = next_values - curr_values;
      
      all_deltas(end+1, :) = deltas;
      append1( all_labels, labels, trial_I{next_order_ind} );
    end
  end
end

end