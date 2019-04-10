function outs = bfw_get_roi_area(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'meta', 'rois' };

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @area_main );
outputs = [ results([results.success]).output ];

outs = struct();
outs.area = vertcat( outputs.area );
outs.labels = vertcat( fcat, outputs.labels );

end

function out = area_main(files)

meta_labels = bfw.struct2fcat( shared_utils.general.get(files, 'meta') );
roi_file = shared_utils.general.get( files, 'rois' );

monk_ids = fieldnames( roi_file );

labels = fcat();
areas = [];

for i = 1:numel(monk_ids)
  monk_id = monk_ids{i};
  
  roi_map = roi_file.(monk_id).rects;
  roi_names = keys( roi_map );
  
  for j = 1:numel(roi_names)
    area = roi_area( roi_map(roi_names{j}) );
    
    area_labels = fcat.with( {'roi', 'looks_by'} );
    setcat( area_labels, {'roi', 'looks_by'}, {roi_names{j}, monk_id} );
    
    append( labels, join(area_labels, meta_labels) );
    areas = [ areas; area ];
  end
end

out = struct();
out.area = areas;
out.labels = labels;

end

function a = roi_area(roi)

w = roi(3) - roi(1);
h = roi(4) - roi(2);

a = w * h;

end