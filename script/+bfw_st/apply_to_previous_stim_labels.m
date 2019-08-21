function apply_to_previous_stim_labels(labels, each, func, varargin)

each_I = findall_or_one( labels, each, varargin{:} );

for idx = 1:numel(each_I)
  each_ind = each_I{idx};

  stim_orders = bfw.parse_prefixed( labels, 'stim_order', each_ind );
  stim_I = findall( labels, 'stim_order', each_ind );
  sorted_orders = sort( stim_orders, 'descen' );

  for i = 1:numel(stim_orders)
    stim_order = stim_orders(i);
    nearest_order = sorted_orders( find(sorted_orders < stim_order, 1) );
    curr_ind = stim_I{i};

    if ( ~isempty(nearest_order) )
      previous_ind = find( labels, sprintf('stim_order__%d', nearest_order) );
    else
      previous_ind = [];
    end
    
    func( labels, previous_ind, curr_ind );
  end
end

end