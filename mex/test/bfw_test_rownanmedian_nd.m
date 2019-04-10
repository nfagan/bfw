function bfw_test_rownanmedian_nd(test_data)

if ( nargin < 1 )
  test_data = load( fullfile(bfw.util.get_project_folder(), 'mex', 'data', 'sf_coh_and_labels.mat') );
end

bfw_test_rowops_nd( @bfw.row_nanmedian, @(x) median(x, 1, 'omitnan'), test_data );

end