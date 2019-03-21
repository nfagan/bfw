function bfw_test_all_rowops_nd(test_data)

if ( nargin < 1 )
  test_data = load( fullfile(bfw.util.get_project_folder(), 'mex', 'data', 'sf_coh_and_labels.mat') );
end

bfw_test_rowmean_nd( test_data );
bfw_test_rownanmean_nd( test_data );
bfw_test_rowsum_nd( test_data );

end