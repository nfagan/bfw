function outs = bfw_make_looking_vector(varargin)

defaults = bfw.get_common_make_defaults();
defaults.rois = 'all';

inputs = { 'aligned_raw_samples/bounds' ...
  , 'aligned_raw_samples/raw_eye_mmv_fixations', 'meta' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.look_vectors = {};
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function outs = main(files, params)

bounds_file = shared_utils.general.get( files, 'bounds' );
fix_file = shared_utils.general.get( files, 'raw_eye_mmv_fixations' );
meta_file = shared_utils.general.get( files, 'meta' );

m_fields = bfw.m_fields( bounds_file );

labels = fcat();
look_vectors = {};

for i = 1:numel(m_fields)
  m_id = m_fields{i};
  
  bounds_map = bounds_file.(m_id);
  fix_vector = columnize( fix_file.(m_id) )';
  
  possible_rois = keys( bounds_map );
  rois = handle_rois( possible_rois, params.rois );
  
  bounds_vectors = eachcell( @(x) columnize(bounds_map(x))', rois );
  look_vecs = eachcell( @(x) x & fix_vector, bounds_vectors );
  
  labs = join( bfw.struct2fcat(meta_file), fcat.create('looks_by', m_id) );
  repmat( labs, numel(look_vecs) );
  addsetcat( labs, 'roi', rois );
  append( labels, labs );
  
  look_vectors = [ look_vectors; look_vecs(:) ];  
end

outs.labels = labels;
outs.look_vectors = look_vectors;

end

function rois = handle_rois(possible_rois, specified_rois)

if ( ischar(specified_rois) && strcmp(specified_rois, 'all') )
  rois = possible_rois;
else
  rois = intersect( possible_rois, cellstr(specified_rois) );
end

end