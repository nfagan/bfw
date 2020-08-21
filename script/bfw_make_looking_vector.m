function outs = bfw_make_looking_vector(varargin)

defaults = bfw.get_common_make_defaults();
defaults.rois = 'all';
defaults.use_degree_criterion = false;
defaults.get_center_func = @get_eyes_nf_center;
defaults.degree_threshold = 20;
defaults.monitor_info = bfw_default_monitor_info();

[params, runner] = bfw.get_params_and_loop_runner( inputs(), '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.look_vectors = {};
  outs.t = {};
  outs.labels = fcat();
else
  outs = shared_utils.struct.soa( outputs );
end

end

function dirs = inputs()

dirs = {  ...
    'aligned_raw_samples/bounds' ...
  , 'aligned_raw_samples/time' ...
  , 'aligned_raw_samples/raw_eye_mmv_fixations' ...
  , 'aligned_raw_samples/position' ...
  , 'rois' ...
  , 'meta'...
};

end

function outs = main(files, params)

bounds_file = shared_utils.general.get( files, 'bounds' );
fix_file = shared_utils.general.get( files, 'raw_eye_mmv_fixations' );
meta_file = shared_utils.general.get( files, 'meta' );
time_file = shared_utils.general.get( files, 'time' );
roi_file = shared_utils.general.get( files, 'rois' );
pos_file = shared_utils.general.get( files, 'position' );

m_fields = bfw.m_fields( bounds_file );

labels = fcat();
look_vectors = {};

for i = 1:numel(m_fields)
  m_id = m_fields{i};
  
  bounds_map = bounds_file.(m_id);
  fix_vector = columnize( fix_file.(m_id) )';
  
  if ( params.use_degree_criterion )
    degree_crit = ...
      handle_degree_criterion( pos_file.(m_id), roi_file.(m_id).rects, params );
  else
    degree_crit = true( size(fix_vector) );
  end
  
  possible_rois = keys( bounds_map );
  rois = handle_rois( possible_rois, params.rois );
  
  bounds_vectors = eachcell( @(x) columnize(bounds_map(x))', rois );
  look_vecs = eachcell( @(x) x & fix_vector & degree_crit, bounds_vectors );
  
  labs = join( bfw.struct2fcat(meta_file), fcat.create('looks_by', m_id) );
  repmat( labs, numel(look_vecs) );
  addsetcat( labs, 'roi', rois );
  append( labels, labs );
  
  look_vectors = [ look_vectors; look_vecs(:) ];
end

outs.labels = prune( bfw.add_monk_labels(labels) );
outs.look_vectors = look_vectors;
outs.t = repmat( {time_file.t}, size(look_vectors) );

end

function degree_crit = handle_degree_criterion(pos, rois, params)

center = feval( params.get_center_func, rois );
px_threshold = bfw.deg2px( params.degree_threshold, params.monitor_info );

deltas = pos - center(:);
len = sqrt( dot(deltas, deltas) );
degree_crit = len < px_threshold;

end

function rois = handle_rois(possible_rois, specified_rois)

if ( ischar(specified_rois) && strcmp(specified_rois, 'all') )
  rois = possible_rois;
else
  rois = intersect( possible_rois, cellstr(specified_rois) );
end

end

function center = get_face_center(rois)

center = roi_center( rois('face') );

end

function center = get_eyes_nf_center(rois)

center = roi_center( rois('eyes_nf') );

end

function center = roi_center(roi)
center = [mean(roi([1, 3])), mean(roi([2, 4]))];
end