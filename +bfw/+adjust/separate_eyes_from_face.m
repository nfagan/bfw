function separate_eyes_from_face(varargin)

ff = @fullfile;

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;

bound_p = bfw.gid( ff('bounds', isd), conf );

bounds = bfw.require_intermediate_mats( params.files, bound_p, params.files_containing );

for i = 1:numel(bounds)
  fprintf( '\n %d of %d', i, numel(bounds) );
  
  bound = shared_utils.io.fload( bounds{i} );
  
  fields = intersect( {'m1', 'm2'}, fieldnames(bound) );
  
  for j = 1:numel(fields)
    c_bounds = bound.(fields{j}).bounds;
    
    assert__has_key( c_bounds, 'face', 'bounds map' );
    assert__has_key( c_bounds, 'eyes', 'bounds map' );
    
    face = c_bounds('face');
    eyes = c_bounds('eyes');
    
    face(eyes) = false;
    
    c_bounds('face') = face;
    
    bound.(fields{j}).bounds = c_bounds;    
  end
  
  if ( ~isfield(bound, 'adjustments') )
    bound.adjustments = containers.Map();
  end
  
  bound.adjustments('separate_eyes_from_face') = params;
  
  save( bounds{i}, 'bound' );
end

end

function assert__has_key( map, key, kind )

if ( ~map.isKey(key) )
  error( 'Map of type "%s" is missing required key "%s".', kind, key );
end

end