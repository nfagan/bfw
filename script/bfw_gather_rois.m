function outs = bfw_gather_rois(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'rois', 'meta' };
[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @main, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );
outs = shared_utils.struct.soa( outputs );

end

function rects = get_rects(roi_file, sub_field)

if ( shared_utils.struct.is_field(roi_file, sub_field) )
  eval( sprintf('rects = roi_file.%s;', sub_field) );  
else
  rects = containers.Map();
end

end

function [linearized_rects, labels] = linearize_rois(rects, looks_by)

linearized_rects = nan( rects.Count, 4 );
k = keys( rects );
labels = cell( rects.Count, 2 );

for i = 1:numel(k)
  linearized_rects(i, :) = rects(k{i});
  labels{i, 1} = k{i};
  labels{i, 2} = looks_by;  
end

categories = { 'roi', 'looks_by' };

if ( isempty(k) )
  labels = fcat.with( categories );
else
  labels = fcat.from( labels, categories );
end

end

function out = main(files, params)

roi_file = shared_utils.general.get( files, 'rois' );
meta_file = shared_utils.general.get( files, 'meta' );

[m1_rects, m1_labels] = linearize_rois( get_rects(roi_file, 'm1.rects'), 'm1' );
[m2_rects, m2_labels] = linearize_rois( get_rects(roi_file, 'm2.rects'), 'm2' );

rects = [ m1_rects; m2_rects ];
append( m1_labels, m2_labels );
join( m1_labels, bfw.struct2fcat(meta_file) );

out = struct();
out.rects = rects;
out.labels = m1_labels;

end