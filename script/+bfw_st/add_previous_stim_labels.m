function labels = add_previous_stim_labels(labels, prev_cat)

if ( nargin < 2 )
  prev_cat = 'previous_stim_type';
end

stim_orders = bfw.parse_prefixed( labels, 'stim_order' );
stim_I = findall( labels, 'stim_order' );
sorted_orders = sort( stim_orders, 'descen' );

addcat( labels, prev_cat );
previous_undefined_label = 'previous_undefined';

for i = 1:numel(stim_orders)
  stim_order = stim_orders(i);
  nearest_order = sorted_orders( find(sorted_orders < stim_order, 1) );
  curr_ind = stim_I{i};
  
  if ( ~isempty(nearest_order) )
    previous_ind = min( find(labels, sprintf('stim_order__%d', nearest_order)) );
    previous_label = cellfun( @(x) sprintf('previous_%s', x) ...
      , cellstr(labels, 'stim_type', previous_ind), 'un', 0 );
  else
    previous_label = previous_undefined_label;
  end
  
  setcat( labels, prev_cat, previous_label, curr_ind );
end

end