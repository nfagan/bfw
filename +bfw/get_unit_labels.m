function labs = get_unit_labels( unit, varargin )

shared_utils.assertions.assert__isa( unit, 'struct', 'the unit' );
shared_utils.assertions.assert__is_scalar( unit );

unit_rating = NaN;
unit_uuid = NaN;
unit_name = 'name__undefined';

if ( isfield(unit, 'rating') )
  unit_rating = unit.rating;
end

if ( isfield(unit, 'uuid') )
  unit_uuid = unit.uuid;
end

if ( isfield(unit, 'name') )
  unit_name = unit.name;
end

channel_str = unit.channel_str;
region = unit.region;

if ( iscellstr(unit_uuid) )
  unit_uuid = unit_uuid{:};
elseif ( ~ischar(unit_uuid) )
  assert( isnumeric(unit_uuid), 'Unit id must be numeric or cellstr.' );
  unit_uuid = num2str( unit_uuid );
end

labs = SparseLabels.create( ...
    'channel', channel_str ...
  , 'region', region ...
  , 'unit_uuid', sprintf( 'unit_uuid__%s', unit_uuid ) ...
  , 'unit_rating', sprintf( 'unit_rating__%d', unit_rating ) ...
  , 'unit_name', unit_name ...
  , varargin{:} ...
);

end