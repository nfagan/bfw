function bfw_test_find_nearest_sorted_real_time_vector()

test_event_file = load( fullfile(bfw.util.get_project_folder(), 'mex', 'data', 'time_vector_and_events.mat') );

events = test_event_file.events;
event_key = test_event_file.event_key;

event_times = events(:, event_key('start_time'));
t = test_event_file.t;

[event_times, sorted_I] = sort( event_times );

tic;
mat_id_time_inds = arrayfun( @(x) shared_utils.sync.nearest(t, x), event_times );
toc;

tic;
mex_id_time_inds = bfw.mex.find_nearest_sorted( t, event_times );
toc;

assert( isequaln(mat_id_time_inds(:), mex_id_time_inds(:)) ...
  , 'Indices between matlab and mex function were different.' );

end