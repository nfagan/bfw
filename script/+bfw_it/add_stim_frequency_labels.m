function labels = add_stim_frequency_labels(labels)

% 0420 -> 100 hz
% 0422, 0426 -> 200 hz
% 0428, 0430 -> 300 hz

ind_100 = findor( labels, {'04202019', '05052019', '06082019'} );
ind_200 = findor( labels, {'04222019', '04262019', '06092019', '06122019'} );
ind_300 = findor( labels, {'04282019', '04302019', '06102019', '06132019'} );

freq_cat = 'stim_frequency';

addcat( labels, freq_cat );
setcat( labels, freq_cat, '100hz', ind_100 );
setcat( labels, freq_cat, '200hz', ind_200 );
setcat( labels, freq_cat, '300hz', ind_300 );

end