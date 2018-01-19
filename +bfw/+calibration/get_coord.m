function val = get_coord(calibration_data, num)
field = get_key_fieldname( num );
validate_key( calibration_data, field );
val = calibration_data.(field).coordinates;
end

function val = get_key_fieldname(num)
val = sprintf( 'key__%d', num );
end

function validate_key(calibration_data, key)
assert( isfield(calibration_data, key), ['the key ''%s'' was not defined' ...
  , ' by the calibration script.'], key );
end