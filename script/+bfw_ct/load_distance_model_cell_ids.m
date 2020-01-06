function labels = load_distance_model_cell_ids(varargin)

load_p = fullfile( bfw.dataroot(varargin{:}), 'analyses' ...
  , 'siqi_distance_model', '121819', 'Model2_SigID_Combined.mat' );

cell_ids = shared_utils.io.fload( load_p );

fs = fieldnames( cell_ids );
labels = fcat();

for i = 1:numel(fs)
  ids = cell_ids.(fs{i});
  ids = ids(:, 21:end);
  
  ids(:, 1) = eachcell( @(x) sprintf('unit_uuid__%d', x), ids(:, 1) );
  ids(:, 3) = eachcell( @(x) sprintf('m1_%s', lower(x)), ids(:, 3) );
  
  tmp_labs = fcat.from( ids, {'unit_uuid', 'region', 'id_m1'} );
  addsetcat( tmp_labs, 'significant_for', fs{i} );

  append( labels, tmp_labs );
end

end