function labels = add_excl_monk_labels(labels)

excl_ind = find( labels, 'exclusive_event' );
m1_ind = find( labels, 'm1', excl_ind );
m2_ind = find( labels, 'm2', excl_ind );

m1_monks = cellstr( labels, 'id_m1', m1_ind );
m2_monks = cellstr( labels, 'id_m2', m2_ind );

excl_m1 = eachcell( @(x) strrep(x, 'm1_', 'excl_'), m1_monks );
excl_m2 = eachcell( @(x) strrep(x, 'm2_', 'excl_'), m2_monks );

excl_cat = 'exclusive_monk_id';
addcat( labels, excl_cat );
setcat( labels, excl_cat, excl_m1, m1_ind );
setcat( labels, excl_cat, excl_m2, m2_ind );

end