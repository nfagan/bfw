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

labs = SparseLabels.create( ...
    'channel', channel_str ...
  , 'region', region ...
  , 'unit_uuid', sprintf( 'unit_uuid__%d', unit_uuid ) ...
  , 'unit_rating', sprintf( 'unit_rating__%d', unit_rating ) ...
  , 'unit_name', unit_name ...
  , varargin{:} ...
);

end