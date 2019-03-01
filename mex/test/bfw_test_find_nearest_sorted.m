function bfw_test_find_nearest_sorted()

iters = 1e2;
time_sz = 1e3;
event_sz = 1e3;

event_func = @() sort( rand(event_sz, 1) * 100 );
nan_event_func = @() generate_nan_vector(event_sz, 0.25);

negative_time_func = @() sort( -rand(time_sz, 1) * 100 );
positive_time_func = @() sort( rand(time_sz, 1) * 100 );
nan_time_func = @() generate_nan_vector( time_sz, 0.25 );

try_run_test_case( positive_time_func, event_func, iters, 'Default case failed' );
try_run_test_case( negative_time_func, event_func, iters, 'Negative case failed' );
try_run_test_case( nan_time_func, event_func, iters, 'NaN time case failed' );

try_run_test_case( positive_time_func, nan_event_func, iters, 'NaN event default case failed' );
try_run_test_case( negative_time_func, nan_event_func, iters, 'NaN event negative case failed' );
try_run_test_case( nan_time_func, nan_event_func, iters, 'NaN event NaN time case failed' );

end

function success = try_run_test_case(time_func, event_func, iters, message)

success = true;

try
  run_test_case( time_func, event_func, iters );
catch err
  base_msg = err.message;
  warning( '\n %s: "%s".', message, base_msg );
  success = false;
end

end

function t_vector = generate_nan_vector(time_size, p_nan)

t_vector = sort( rand(time_size, 1) );
n_nan = floor( time_size * p_nan );

for i = 1:n_nan
  ind = randi( time_size );
  t_vector(ind) = nan;
end

end

function run_test_case(time_func, event_func, iters)

ts = zeros( iters, 2 );

for i = 1:iters
  time_vec = time_func();
  event_vec = event_func();
  
  tic;
  mex_v = bfw.mex.find_nearest_sorted( time_vec, event_vec );
  ts(i, 1) = toc();
  
  tic;
  matlab_v = shared_utils.sync.nearest( time_vec, event_vec );
  ts(i, 2) = toc();
  
  mex_v = double( mex_v(:) );
  matlab_v = matlab_v(:);
  matlab_v(isnan(matlab_v)) = 0;
  
  if ( ~isequaln(mex_v, matlab_v) )
    is_mismatching = mex_v ~= matlab_v;
    error( 'Found arrays mismatch: %d mismatches', sum(is_mismatching) );
  end
end

mean_mex_time = mean( ts(:, 1) );
mean_mat_time = mean( ts(:, 2) );
factor = mean_mat_time / mean_mex_time;

fprintf( '\n Ok. mean mex time: %0.3f (ms); mean mat time: %0.3f (ms); factor %0.3f' ...
  , mean_mex_time, mean_mat_time, factor );

end

% bfw.mex.build_single_file('find_nearest_sorted.cpp');


