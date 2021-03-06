function separate_mouth_from_face(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

bound_p = bfw.get_intermediate_directory( 'bounds' );

bounds = bfw.require_intermediate_mats( params.files, bound_p, params.files_containing );

for i = 1:numel(bounds)
  fprintf( '\n %d of %d', i, numel(bounds) );
  
  bound = shared_utils.io.fload( bounds{i} );
  
  fields = { 'm1', 'm2' };
  
  for j = 1:numel(fields)
    c_bounds = bound.(fields{j}).bounds;
    
    assert__has_key( c_bounds, 'face', 'bounds map' );
    assert__has_key( c_bounds, 'mouth', 'bounds map' );
    
    face = c_bounds('face');
    mouth = c_bounds('mouth');
    
    face(mouth) = false;
    
    c_bounds('face') = face;
    
    bound.(fields{j}).bounds = c_bounds;    
  end
  
  if ( ~isfield(bound, 'adjustments') )
    bound.adjustments = containers.Map();
  end
  
  bound.adjustments('separate_mouth_from_face') = params;
  
  save( bounds{i}, 'bound' );
end

end

function assert__has_key( map, key, kind )

if ( ~map.isKey(key) )
  error( 'Map of type "%s" is missing required key "%s".', kind, key );
end

end