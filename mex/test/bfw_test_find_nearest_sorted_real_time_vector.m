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

%%

check_mat = mat_id_time_inds(:);
check_mex = double( mex_id_time_inds(:) );

differences = check_mat - check_mex;

if ( ~all(differences == 0) )
  assert( max(abs(differences)) == 1, 'More than 1 index of difference.' );
  
  num_diffs = find( differences ~= 0 );
  
  for i = 1:numel(num_diffs)
    m_ind = num_diffs(i);
    
    mat_ind = check_mat(m_ind);
    mex_ind = check_mex(m_ind);
    
    mat_offset = abs( t(mat_ind) - event_times(m_ind) );
    mex_offset = abs( t(mex_ind) - event_times(m_ind) );
    
    assert( isequal(mat_offset, mex_offset), 'Discrepencies were not equal.' );
  end
end

end