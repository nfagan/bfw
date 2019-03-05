function bfw_test_find_nearest_real_time_vector()

test_event_file = load( fullfile(bfw.util.get_project_folder(), 'mex', 'data', 'time_vector_and_events.mat') );

events = test_event_file.events;
event_key = test_event_file.event_key;

event_times = events(:, event_key('start_time'));
t = test_event_file.t;

mat_inds = arrayfun( @(x) shared_utils.sync.nearest(t, x), event_times );
mex_inds = bfw.find_nearest( t, event_times );

check_mat = mat_inds(:);
check_mex = double( mex_inds(:) );

assert( isequaln(check_mat, check_mex), 'Indices between matlab and mex function were different.' );

end