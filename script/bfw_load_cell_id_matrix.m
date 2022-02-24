function mat = bfw_load_cell_id_matrix(conf)

if ( nargin < 1 || isempty(conf) )
  conf = bfw.config.load();
end

mat = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'public/unit_ids/id_matrix.mat') );

end