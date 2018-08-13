aligned_file = bfw.load_one_intermediate( 'aligned', '01162018_position_1.mat' );
roi_file = bfw.load_one_intermediate( 'rois', '01162018_position_1.mat' );
events_file = bfw.load_one_intermediate( 'events_per_day', '01162018_position_1.mat' );
bounds_file = bfw.load_one_intermediate( 'bounds', '01162018_position_1.mat' );

pos = aligned_file.m1.position;

in_bounds = bfw.bounds.rect( pos(1, :), pos(2, :), roi_file.m1.rects('eyes') );

[new_bin1, new_ind1] = bfw.binned_any( in_bounds, 10 );
[old_bin1, old_bint] = bfw.slide_window( in_bounds, aligned_file.m1.plex_time, 500, 10 );

new_t = aligned_file.m1.plex_time( new_ind1 );

new_starts = shared_utils.logical.find_starts( new_bin1, 1 );
old_starts = shared_utils.logical.find_starts( old_bin1, 1 );

% assert( isequal(new_starts, old_starts) );

new_event_times = new_t( new_starts );
old_event_times = old_bint( old_starts );

events_m1_eyes = events_file.event_info({'m1', 'eyes', '01162018_position_1.mat'});
events_m1_eyes = set_data( events_m1_eyes, events_m1_eyes.data(:, events_file.event_info_key('times')) );



%%

evt1 = events_m1_eyes.data(1);
% evt1 = old_event_times(1);

[~, i] = min( abs(evt1 - aligned_file.m1.plex_time) );

figure(1); clf();

look_back = -10;
look_ahead = -look_back;

subset_x = pos(1, i+look_back:i+look_ahead);
subset_y = pos(2, i+look_back:i+look_ahead);

scatter( subset_x, subset_y, 'k' );

hold on;

ib = bfw.bounds.rect( subset_x, subset_y, roi_file.m1.rects('eyes') );

scatter( subset_x(ib), subset_y(ib), 'r' );

% plot( pos(1, i-100:i+100), 'r' ); hold on;
% plot( pos(2, i-100:i+100), 'b' );

