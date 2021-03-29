test_flip = false;
num_days = [];

mutual_join_evt = find_joint_mutul_type_event( m1m2_evts_2_flip, test_flip, num_days );

%%

root_p = 'C:\Users\nick\Downloads\code for generating interactive events';

use_corr_gaze = true;
use_gaze_control = true;

if ( use_gaze_control )
%   mutual_join_evt_orig = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_NO_GAZE_CONTROL.mat') );
%   mutual_join_evt_flipped = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_NO_GAZE_CONTROL_FLIPPED.mat') );
  
  mutual_join_evt_orig = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_GAZE_CONTROL_NEW_FOLLOW.mat') );
  mutual_join_evt_flipped = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_GAZE_CONTROL_FLIPPED_NEW_FOLLOW.mat') );
  
  
elseif ( use_corr_gaze )
  mutual_join_evt_orig = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_CORRECT_GAZE.mat') );
  mutual_join_evt_flipped = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_FLIPPED_CORRECT_GAZE.mat') );
else
  mutual_join_evt_orig = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade.mat') );
  mutual_join_evt_flipped = shared_utils.io.fload( fullfile(root_p, 'mutual_join_evt_eyes_remade_FLIPPED.mat') );
end

%%

count_m1 = @(x) cellfun(@(y) sum(y.m1 == 1), x);
count_m2 = @(x) cellfun(@(y) sum(y.m2 == 1), x);

orig_num_m1 = count_m1( mutual_join_evt_orig );
orig_num_m2 = count_m2( mutual_join_evt_orig );
flipped_num_m1 = count_m1( mutual_join_evt_flipped );
flipped_num_m2 = count_m2( mutual_join_evt_flipped );

assert( all(orig_num_m1 == flipped_num_m2) && all(orig_num_m2 == flipped_num_m1) );

%%

cc_labs_orig = make_combined_labels( mutual_join_evt_orig, m1m2_evts_2_flip );
cc_labs_flip = make_combined_labels( mutual_join_evt_flipped, m1m2_evts_2_flip );

ind_orig = find( cc_labs_orig, {'m2-follow', 'joint'} );
ind_flipped = find( cc_labs_flip, {'m1-follow', 'joint'} );

assert( numel(ind_orig) == numel(ind_flipped) );
% assert( count(cc_labs_orig, 'm2-follow') == count(cc_labs_flip, 'm1-follow') );

%%

for i = 1:numel(mutual_join_evt_orig)
  joint_m1 = sum( mutual_join_evt_orig{i}.m1 == 1 );
  joint_m2 = sum( mutual_join_evt_orig{i}.m2 == 1 );
  
  flipped_joint_m1 = sum( mutual_join_evt_flipped{i}.m2 == 1 );
  flipped_joint_m2 = sum( mutual_join_evt_flipped{i}.m1 == 1 );
  
  assert( joint_m1 == flipped_joint_m1 );
  assert( joint_m2 == flipped_joint_m2 );
end

%%

% mutual_join_evt = mutual_join_evt_flipped;
% mutual_join_evt = mutual_join_evt_part_flipped;
mutual_join_evt = mutual_join_evt_orig;

cc_labs = make_combined_labels( mutual_join_evt, m1m2_evts_2_flip );

%%

mask = find( cc_labs, {'follow', '<event-type>', 'interactive-event'} );
[cts, count_labels] = counts_of( cc_labs, {'session', 'data-type'}, 'followed-by', mask );

pl = plotlabeled.make_common();
% pl.error_func = @plotlabeled.nanstd;
pl.match_y_lims = false;
pl.add_points = true;
pl.points_are = 'session';

axs = pl.bar( cts, count_labels, 'followed-by', {}, {'data-type', 'event-type'} );

%%  raw event counts

mask = find( cc_labs, {'interactive-event'} );
[count_labels, ct_I] = keepeach( cc_labs', {'session', 'followed-by'}, mask );
cts = cellfun( @numel, ct_I );

pl = plotlabeled.make_common();
% pl.error_func = @plotlabeled.nanstd;
pl.match_y_lims = false;
pl.add_points = true;
pl.points_are = 'session';

axs = pl.bar( cts, count_labels, 'followed-by', {}, {'data-type'} );

%%  hist

mask = find( cc_labs, 'joint' );
[cts, count_labels] = counts_of( cc_labs, {'session', 'data-type'}, 'followed-by', mask );

pl = plotlabeled.make_common();
pl.hist_add_summary_line = true;
axs = pl.hist( cts, count_labels, {'followed-by', 'data-type'}, 100 );

function cc_labs = make_combined_labels(mutual_join_evt, m1m2_evts_2_flip)

%{

mutual_join_evt field info

m1 % event type: m2 initiates, m1 follows: 1 is joint, 2 is follow, 0 is solo
m2 % event type: m1 initiates, m2 follows: ""

m2se % start and end of m2 initiation
m2m1 % start and end of m1 join

%}

cc_labs = fcat();
cc_event_labs = fcat();

for i = 1:numel(mutual_join_evt)
  evts = m1m2_evts_2_flip{i};
  
  session_lab = sprintf( 'session-%d', i );
  labs = cc_make_event_type_labels( mutual_join_evt{i}.m1, mutual_join_evt{i}.m2 );
  addsetcat( labs, 'session', session_lab );
  append( cc_labs, labs );
  
  cc_evt_labs = fcat.create( ...
      'session', session_lab ...
    , 'followed-by', [repmat({'m1-follow'}, numel(evts.m1), 1); repmat({'m2-follow'}, numel(evts.m2), 1)] ...
    , 'initiated-by', '<initiated-by>' ...
    , 'event-type', '<event-type>' ...
    );
  append( cc_event_labs, cc_evt_labs );
end

addsetcat( cc_labs, 'data-type', 'interactive-event' );
addsetcat( cc_event_labs, 'data-type', 'source-event' );

cc_labs = [ cc_labs; cc_event_labs ];

end