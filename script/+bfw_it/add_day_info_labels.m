function labels = add_day_info_labels(labels, day_info_xls, mask)

if ( nargin < 3 )
  mask = rowmask( labels );
end

validateattributes( day_info_xls, {'containers.Map'}, {}, mfilename, 'day_info_xls' );
validateattributes( labels, {'fcat'}, {}, mfilename, 'labels' );

if ( isempty(mask) )
  return;
end

dates = day_info_xls('date');
freqs = day_info_xls('frequency');
impedances = day_info_xls('impedance');
monks = day_info_xls('monkey');
regions = day_info_xls('region');
designs = day_info_xls('experiment_design');

current_date = combs( labels, 'session', mask );

if ( numel(current_date) ~= 1 )
  error( 'Expected 1 "session"; got %d', numel(current_date) ); 
end

session_ind = strcmp( dates, current_date );

if ( nnz(session_ind) ~= 1 )
  error( 'No matching session in xls file for "%s".', char(current_date) );
end

freq = sprintf( '%dhz', freqs(session_ind) );
imp = sprintf( '%dohm', impedances(session_ind) );
monk = sprintf( 'm1_%s', monks{session_ind} );
region = regions{session_ind};
design = designs{session_ind};

cats = { 'stim_frequency', 'block_design', 'impedance', 'id_m1', 'region' };
values = {freq, design, imp, monk, region};
values = repmat( values, numel(mask), 1 );

addcat( labels, cats );
setcat( labels, cats, values, mask );

end
