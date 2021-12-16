%%  define interactive events

function bfw_make_cc_interactive_and_solo_events(interactive_event_info, regular_events)

if ( nargin < 1 || isempty(interactive_event_info) )

interactive_event_info = define_interactive_event_nf_edit( ...
    'is_parallel', true ...
  , 'use_nf_follow_method', true ...
  , 'roi', 'eyes_nf' ...
);

end

%%  linearize interactive events

cc_evt_info = bfw_load_cc_eye_interactive_events( bfw.config.load() );

tmp_inter_event_info = interactive_event_info;
tmp_inter_event_info.m1m2_evts = tmp_inter_event_info.m1m2_evts_2;

[~, ~, cc_labels, ~, cc_outs] = ...
  bfw_extract_cc_interactive_event_info( tmp_inter_event_info, cc_evt_info.cc_time_file, 'eyes' );

%%  gather non-interactive events

if ( nargin < 2 || isempty(regular_events) )
  regular_events = bfw_gather_events( 'event_subdir', 'remade_032921', 'require_stim_meta', false );
end

%%  keep solo events that don't overlap with an interactive event

i_starts = cc_outs.event_portion_ts(:, 1);
i_stops = cc_outs.event_portion_ts(:, end); % end of any part of interactive event, not just the joint part per se.
i_start_stop = [ i_starts, i_stops ];
i_durs = i_stops - i_starts;

i_init_start = cc_outs.event_portion_ts(:, 2);
i_term_start = cc_outs.event_portion_ts(:, 3);

i_init_dur = i_term_start - i_init_start;
i_term_dur = i_stops - i_term_start;

i_labels = cc_labels';
i_mask = find( i_labels, 'join' );
i_looks_by = cellfun( @(x) strrep(x, '-follow', ''), cellstr(i_labels, 'followed-by'), 'un', 0 );
i_event_type = i_looks_by;
i_event_type(strcmp(i_event_type, 'm1') | strcmp(i_event_type, 'm2')) = { 'interactive' };

e_starts = bfw.event_column( regular_events, 'start_time' );
e_stops = bfw.event_column( regular_events, 'stop_time' );
e_start_stop = [e_starts, e_stops];
e_labels = regular_events.labels';
e_mask = find( e_labels, {'m1', 'm2', 'eyes_nf'} );
e_durs = e_stops - e_starts;
e_looks_by = cellstr( e_labels, 'looks_by' );

each = { 'session' };

e_keep_inds = bfw_remove_overlapping_exclusive_events( ...
    i_start_stop, i_labels, i_mask ...
  , e_start_stop, e_labels, e_mask, each ...
);

%%  keep solo events that aren't within +/- 1s of eachother

e_keep_events_m1 = bfw_remove_solo_within( regular_events, [-1e3, 1e3], 'm1' );
e_keep_events_m2 = bfw_remove_solo_within( regular_events, [-1e3, 1e3], 'm2' );
e_keep_events = intersect( e_keep_events_m1, e_keep_events_m2 );
e_keep_events = intersect( e_keep_events, e_keep_inds );

%%  combine solo + interactive events

all_start_ts = [ e_starts(e_keep_events); i_starts(i_mask) ];
all_durs = [ e_durs(e_keep_events); i_durs(i_mask) ];
all_events = [ all_start_ts, all_durs ];

all_looks_by = [ e_looks_by(e_keep_events); i_event_type(i_mask) ];
all_sessions = [ e_labels(e_keep_events, 'session'); i_labels(i_mask, 'session') ];
all_labels = fcat.create( 'looks_by', all_looks_by, 'session', all_sessions, 'roi', 'eyes_nf' );

event_key = containers.Map();
event_key('start_time') = 1;
event_key('duration') = 2;

%%

% bfw_plot_event_timeline( all_events, event_key, all_labels', ...
%     'figures', 'session' ...
%   , 'use_looks_by_order', true ...
%   , 'looks_by_order', {'interactive', 'm1', 'm2'} ...
%   , 'mask_func', @(l, m) find(l, {'01022019', 'm1', 'm2', 'interactive'}, m) ...
%   , 'y_lims', [-2, 5] ...
%   , 'box_height', 1 ...
%   , 'box_y_offset', 2 ...
% );

end