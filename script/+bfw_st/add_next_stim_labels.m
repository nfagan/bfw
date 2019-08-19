function labels = add_next_stim_labels(labels, next_cat)

if ( nargin < 2 )
  next_cat = 'next_stim_type';
end

stim_orders = bfw.parse_prefixed( labels, 'stim_order' );
stim_I = findall( labels, 'stim_order' );
sorted_orders = sort( stim_orders );

addcat( labels, next_cat );
next_undefined_label = 'next_undefined';

for i = 1:numel(stim_orders)
  stim_order = stim_orders(i);
  nearest_order = sorted_orders( find(sorted_orders > stim_order, 1) );
  curr_ind = stim_I{i};
  
  if ( ~isempty(nearest_order) )
    next_ind = min( find(labels, sprintf('stim_order__%d', nearest_order)) );
    next_label = cellfun( @(x) sprintf('next_%s', x) ...
      , cellstr(labels, 'stim_type', next_ind), 'un', 0 );
  else
    next_label = next_undefined_label;
  end
  
  setcat( labels, next_cat, next_label, curr_ind );
end

end