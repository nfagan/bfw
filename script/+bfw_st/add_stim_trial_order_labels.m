function labels = add_stim_trial_order_labels(labels, stim_ts, order_cat)

if ( nargin < 3 )
  order_cat = 'stim_order';
end

assert_ispair( stim_ts(:), labels );
[~, order] = sort( stim_ts );
order_labels = arrayfun( @(x) sprintf('%s__%d', order_cat, x), order, 'un', 0 );
addsetcat( labels, order_cat, order_labels );

end