function day_info = process_day_info_xls(raw)

validateattributes( raw, {'cell'}, {'2d', 'nonempty'}, mfilename, 'raw' );
header = raw(1, :);
assert( iscellstr(header), 'Header must be cell array of strings.' );

raw(find_all_nan_rows(raw), :) = [];

if ( size(raw, 1) < 2 )
  error( 'Day info xls data has no entries after header.' );
end

required_fields = { 'date', 'monkey', 'region', 'frequency', 'impedance', 'experiment design' };
field_inds = assert_find_in_header( header, required_fields );

day_info = containers.Map();

day_info('date') = process_dates( raw, field_inds(1) );
day_info('monkey') = process_monks( raw, field_inds(2) );
day_info('region') = process_regions( raw, field_inds(3) );
day_info('frequency') = process_frequencies( raw, field_inds(4) );
day_info('impedance') = process_impedances( raw, field_inds(5) );
day_info('experiment_design') = process_experiment_design( raw, field_inds(6) );

validate_day_info( day_info );

end

function should_exclude = find_all_nan_rows(raw)

should_exclude = true( size(raw, 1), 1 );

for i = 1:size(raw, 1)  
  for j = 1:size(raw, 2)
    v = raw{i, j};
    
    if ( ~isscalar(v) || ~isnan(v) )
      should_exclude(i) = false;
      break;
    end
  end
end

end

function validate_day_info(day_info)

fields = keys( day_info );

for i = 1:numel(fields)
  value = day_info(fields{i});
  
  if ( i == 1 )
    expect_n = numel( value );
  elseif ( numel(value) ~= expect_n )
    error( 'Columns have mismatching numbers of rows; "%s" has %d; "%s" has %d.' ...
      , fields{1}, expect_n, fields{i}, numel(value) );
  end
end

no_stim = find( strcmp(day_info('region'), 'no stimulation') );
check_nan_fields = { 'frequency', 'impedance' };

for i = 1:numel(check_nan_fields)
  to_check = day_info(check_nan_fields{i});
  nan_inds = find( isnan(to_check) );
  
  if ( ~isequal(nan_inds, no_stim) )
    error( 'Missing value for "%s".', check_nan_fields{i} );
  end
end

end

function design = process_experiment_design(raw, design_ind)

design = raw(2:end, design_ind );
assert( iscellstr(design), 'Experiment design info must be cell array of strings.' );
design = lower( design );

end

function imp = process_impedances(raw, imp_ind)

imp = raw(2:end, imp_ind);
cellfun( @(x) validateattributes(x, {'double'}, {'scalar'}, mfilename, 'impedance'), imp );
imp = cell2mat( imp );

end

function freqs = process_frequencies(raw, freq_ind)

freqs = raw(2:end, freq_ind);
cellfun( @(x) validateattributes(x, {'double'}, {'scalar'}, mfilename, 'frequency'), freqs );
freqs = cell2mat( freqs );

end

function regions = process_regions(raw, region_ind)

regions = raw(2:end, region_ind );
assert( iscellstr(regions), 'Region names must be cell array of strings.' );
regions = lower( regions );

end

function monks = process_monks(raw, monk_ind)

monks = raw(2:end, monk_ind );
assert( iscellstr(monks), 'Monkey names must be cell array of strings.' );
monks = lower( monks );

end

function out_dates = process_dates(raw, date_ind)

dates = raw(2:end, date_ind);
out_dates = cell( size(dates) );

for i = 1:numel(dates)
  validateattributes( dates{i}, {'char'}, {}, mfilename, 'date' );
  
  date = strrep( dates{i}, '"', '' );
  
  date_components = strsplit( date, '/' );
  if ( numel(date_components) ~= 3 )
    error( 'Invalid date format for entry: "%s"; expected mm/dd/yyyy', date );
  end
  
  month = date_components{1};
  day = date_components{2};
  year = date_components{3};
  
  assert( numel(day) == 1 || numel(day) == 2, 'Number of day chars must be 1 or 2' );
  assert( numel(month) == 1 || numel(month) == 2, 'Number of month chars must be 1 or 2' );
  assert( numel(year) == 4, 'Number of year chars must be 4.' );
  
  if ( numel(day) < 2 )
    day = sprintf( '0%s', day );
  end
  if ( numel(month) < 2 )
    month = sprintf( '0%s', month );
  end
  
  out_dates{i} = sprintf( '%s%s%s', month, day, year );
end

end

function inds = assert_find_in_header(header, names)

inds = zeros( size(names) );

for i = 1:numel(names)
  matches = find( strncmpi(header, names{i}, numel(names{i})) );
  
  if ( numel(matches) ~= 1 )
    error( 'Expected 1 match in header for "%s"; got %d.', names{i}, numel(matches) );
  end
  
  inds(i) = matches;
end

end