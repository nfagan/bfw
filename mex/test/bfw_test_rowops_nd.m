function bfw_test_rowops_nd(mex_func, mat_func, test_data)

if ( nargin < 3 )
  test_data = load( fullfile(bfw.util.get_project_folder(), 'mex', 'data', 'sf_coh_and_labels.mat') );
end

iters = 100;
max_dims = 7;

test_complete_subset( mex_func, mat_func, test_data, iters, 200 );
test_rand_dims( mex_func, mat_func, iters, max_dims );
test_empty( mex_func, mat_func );

end

function test_empty(mex_func, mat_func)

mat_empty = rowop( [], {}, mat_func );
mex_empty = mex_func( [], {} );

assert( isequal(mat_empty, mex_empty), 'Empty arrays were not equal.' );

a = rand( 5, 5 );

mat_empty2 = rowop( a, {}, mat_func );
mex_empty2 = mex_func( a, {} );

assert( isequal(mat_empty2, mex_empty2), 'Empty arrays with empty indices were not equal.' );

end

function test_rand_dims(mex_func, mat_func, iters, max_dims)

max_sz = 5;
max_inds = 10;

for i = 1:iters
  n_dims = randi( max_dims );
  n_inds = randi( max_inds );
  
  sz_vec = arrayfun( @(x) randi(max_sz), 1:n_dims );
  
  a = rand( sz_vec );
  max_rows = size( a, 1 );
  
  I = arrayfun( @(x) uint64(randperm(max_rows, randi(max_rows))), 1:n_inds, 'un', 0 );
  
  mat_a = rowop( a, I, mat_func );
  mex_a = mex_func( a, I );
  
  assert( isequal(mat_a, mex_a), 'Randomly created subsets were not equal.' );
end

end

function test_complete_subset(mex_func, mat_func, test_data, iters, max_sz)

data = test_data.subset_coh;
labs = test_data.subset_labs;

all_categories = getcats( labs );

ts = zeros( iters, 2 );
max_sz = min( rows(labs), max_sz );

for i = 1:iters
  cat_inds = randperm( numel(all_categories), randi(numel(all_categories)) );
  use_cats = all_categories(cat_inds);
  
  row_ind = randperm( rows(labs), max_sz );
  
  I = findall( labs, use_cats, row_ind );
  
  tic;
  mat_data = rowop( data, I, mat_func );
  ts(i, 1) = toc();
  
  tic;
  mex_data = mex_func( data, I );
  ts(i, 2) = toc();
  
  assert( isequaln(mat_data(isnan(mat_data)), mex_data(isnan(mex_data))) && ...
    isequal(isnan(mat_data), isnan(mex_data)), 'NaN subsets were not equal.' );
  
  assert( isequaln(mat_data, mex_data), 'Subsets were not equal.' );  
end

factors = ts(:, 2) ./ ts(:, 1);

fprintf( '\n Mean factor (mex / mat): %0.3f\n', mean(factors) );

end