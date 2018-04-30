function outs = bin_look_events_by_stim(look_ahead)

stim_p = bfw.get_intermediate_directory( 'stim' );
unified_p = bfw.get_intermediate_directory( 'unified' );
aligned_p = bfw.get_intermediate_directory( 'aligned' );
events_p = bfw.get_intermediate_directory( 'events_per_day' );
bounds_p = bfw.get_intermediate_directory( 'bounds' );

mats = bfw.require_intermediate_mats( [], stim_p, [] );

outs = struct();
outs.n_fix = Container();
outs.fix_dur = Container();
outs.total_dur = Container();
outs.p_look_back = Container();
outs.p_in_bounds = Container();
outs.vel = Container();

for i = 1:numel(mats)

stim_file = shared_utils.io.fload( mats{i} );

un_filename = stim_file.unified_filename;

un_file = shared_utils.io.fload( fullfile(unified_p, un_filename) );
events_file = shared_utils.io.fload( fullfile(events_p, un_filename) );
bounds_file = shared_utils.io.fload( fullfile(bounds_p, un_filename) );
aligned_file = shared_utils.io.fload( fullfile(aligned_p, un_filename) );

session_alias = sprintf( 'session__%d', un_file.m1.mat_index );

if ( events_file.is_link )
  events_file = shared_utils.io.fload( fullfile(events_p, events_file.data_file) );
end

%
% bounds psth
%

plex_time = aligned_file.m1.plex_time;
mat_time = aligned_file.m1.time;
lb = -1e3 / bounds_file.step_size;
la = 5e3 / bounds_file.step_size;

bounds = bounds_file.m1.bounds('eyes');

[stim_bounds_psth, stim_bounds_t] = bounds_psth( bounds, bounds_file.m1.time ...
  , plex_time, mat_time, stim_file.stimulation_times, lb, la );
sham_bounds_psth = bounds_psth( bounds, bounds_file.m1.time ...
  , plex_time, mat_time, stim_file.sham_times, lb, la );

base_labs = SparseLabels.create( ...
    'date', un_file.m1.date ...
  , 'day', datestr(un_file.m1.date, 'mmddyy') ...
  , 'unified_filename', un_filename ...
  , 'session', session_alias ...
  , 'stim_type', 'stimulate' ...
  , 'meas_type', 'n_fix' ...
  , 'fix_n', '<fix_n>' ...
  , 'look_ahead', sprintf('look_ahead__%0.3f', look_ahead) ...
);

ib_labs = set_field( base_labs, 'meas_type', 'p_inbounds' );
ib_labs = add_field( ib_labs, 'looks_to', 'eyes' );

stim_bounds_psth = Container( stim_bounds_psth, ib_labs );
sham_bounds_psth = Container( sham_bounds_psth, set_field(ib_labs, 'stim_type', 'sham') );

outs.p_in_bounds = extend( outs.p_in_bounds, stim_bounds_psth, sham_bounds_psth );
outs.p_in_bounds_t = stim_bounds_t * bounds_file.step_size;

%
% velocities
%

v_lb = 0;
v_la = 2e3;
pos = aligned_file.m1.position;

vpsth_stim = velocity_psth( pos, plex_time, stim_file.stimulation_times, v_lb, v_la );
vpsth_sham = velocity_psth( pos, plex_time, stim_file.sham_times, v_lb, v_la );

vel_labs = set_field( ib_labs, 'meas_type', 'velocity' );
vel_labs = set_field( vel_labs, 'look_ahead', sprintf('look_ahead__%0.3f', v_la/1e3) );

vpsth_stim = Container( vpsth_stim, vel_labs );
vpsth_sham = Container( vpsth_sham, set_field(vel_labs, 'stim_type', 'sham') );

outs.vel = extend( outs.vel, vpsth_stim, vpsth_sham );


%
% duration
%

one_session_events = only( events_file.event_info, un_filename );
one_session_events = only( one_session_events, {'m1'} );

[I, C] = get_indices( one_session_events, {'looks_to', 'looks_by'} );

for j = 1:numel(I)
  subset_events = one_session_events(I{j});
  one_labs = one( subset_events.labels );

  event_times = subset_events.data(:, events_file.event_info_key('times'));
  event_durations = subset_events.data(:, events_file.event_info_key('durations'));

  [binned_stim, stim_ind] = bin_by_stim( event_times, stim_file.stimulation_times, look_ahead );
  [binned_sham, sham_ind] = bin_by_stim( event_times, stim_file.sham_times, look_ahead );
  
  %
  %   duration 
  %

  stim_durs = cellfun( @(x) event_durations(x), stim_ind, 'un', false );
  sham_durs = cellfun( @(x) event_durations(x), sham_ind, 'un', false );

  n_stim = cellfun( @numel, binned_stim );
  n_sham = cellfun( @numel, binned_sham );

  total_time_stim = cellfun( @sum, stim_durs );
  total_time_sham = cellfun( @sum, sham_durs );

  one_look_labs = mergelabs( base_labs, one_labs );

  dur_labs = set_field( one_look_labs, 'meas_type', 'duration' );
  total_dur_labs = set_field( one_look_labs, 'meas_type', 'total_duration' );
  p_look_labs = set_field( one_look_labs, 'meas_type', 'p_lookback' );

  n_stim = Container( n_stim(:), one_look_labs );
  n_sham = Container( n_sham(:), set_field(one_look_labs, 'stim_type', 'sham') );

  outs.n_fix = extend( outs.n_fix, n_stim, n_sham );

  total_time_stim = Container( total_time_stim(:), total_dur_labs );
  total_time_sham = Container( total_time_sham(:), set_field(total_dur_labs, 'stim_type', 'sham') );

  outs.total_dur = extend( outs.total_dur, total_time_stim, total_time_sham );

  stim_durs = stim_durs( ~cellfun(@isempty, stim_durs) );
  sham_durs = sham_durs( ~cellfun(@isempty, sham_durs) );

  if ( ~isempty(stim_durs) )
    fix_n = get_fix_n( stim_durs );
    stim_durs = Container( cell2mat(stim_durs(:)), dur_labs );
    stim_durs('fix_n') = fix_n;
    outs.fix_dur = append( outs.fix_dur, stim_durs );
  end

  if ( ~isempty(sham_durs) )
    fix_n = get_fix_n( sham_durs );
    sham_durs = Container( cell2mat(sham_durs(:)), set_field(dur_labs, 'stim_type', 'sham') );
    sham_durs('fix_n') = fix_n;
    outs.fix_dur = append( outs.fix_dur, sham_durs );
  end

  %
  % p look back
  %

  lb = -0.5;
  la = 5;
  bw = 0.5;
  ss = 0.1;

  [stim_counts, t] = p_look_back( stim_file.stimulation_times, event_times, lb, la, bw, ss );
  sham_counts = p_look_back( stim_file.sham_times, event_times, lb, la, bw, ss );

  if ( numel(stim_file.stimulation_times) == 0 )
    stim_counts = zeros( 1, numel(t) );
%     stim_counts = [];
  else
%     max_val = max( stim_counts );
    max_val = numel( stim_file.stimulation_times );
    stim_counts = stim_counts(:)' / max_val;
  end

  if ( numel(stim_file.sham_times) == 0 )
    sham_counts = zeros( 1, numel(t) );
  else
%     max_val = max( sham_counts );
    max_val = numel( stim_file.sham_times );
    sham_counts = sham_counts(:)' / max_val;
  end

  stim_p = Container( stim_counts, p_look_labs );
  sham_p = Container( sham_counts, set_field(p_look_labs, 'stim_type', 'sham') );

  outs.p_look_back = extend( outs.p_look_back, stim_p, sham_p );
  outs.p_look_back_t = t;
  
end
end

end

function vs = velocity_psth(pos, plex_t, event_times, lb, la)

first_t = find( plex_t > 0, 1, 'first' );
plex_t = plex_t(first_t:end);
pos = pos(:, first_t:end);

filt_order = 4;
frame_len = 21;

vs = zeros( numel(event_times), 1 );

for i = 1:numel(event_times)
  [~, I] = min( abs(plex_t - event_times(i)) );
  
  x = pos(1, I+lb:I+la);
  y = pos(2, I+lb:I+la);
  
  x_prime = sgolayfilt( x, filt_order, frame_len );
  y_prime = sgolayfilt( y, filt_order, frame_len );
  
  xvel = nanmean( abs(diff(x_prime)) );
  yvel = nanmean( abs(diff(y_prime)) );
 
  vs(i) = (xvel + yvel) / 2;
end

vs = vs * 1e3;

end

function [all_b, t_series] = bounds_psth( bounds, bounds_time, plex_time, mat_time, events, lb, la )

first_t = find( plex_time > 0, 1, 'first' );
plex_t = plex_time(first_t:end);
mat_t = mat_time(first_t:end);

t_series = lb:la;

all_b = nan( numel(events), numel(t_series) );

for i = 1:numel(events)
  
  [~, plex_ind] = min( abs(plex_t - events(i)) );
  t = mat_t(plex_ind);
  [~, bounds_ind] = min( abs(bounds_time - t) );
  
  b = bounds(bounds_ind+lb:bounds_ind+la);
  
  all_b(i, :) = b;
end

all_b = sum(all_b, 1) ./ numel(events);

end

function durs = get_fix_n(durs)
durs = cellfun( @(x) 1:numel(x), durs, 'un', false );
durs = cellfun( @(x) arrayfun(@(y) sprintf('fix_n__%d', y), x, 'un', false) ...
  , durs, 'un', false );
durs = [ durs{:} ];
durs = durs(:);
end

function [outs, I] = bin_by_stim(events, stim_times, look_ahead)

outs = cell( 1, numel(stim_times) );
I = cell( size(outs) );

for i = 1:numel(stim_times)
  st = stim_times(i);
  ind = events >= st & events < st + look_ahead;
  outs{i} = events(ind);
  I{i} = ind;
end

end

function [counts, t] = p_look_back(target_evts, all_evts, lb, la, bw, ss)

[counts, t] = bfw.slide_window_counts( target_evts(:), all_evts(:), bw, ss, lb, la );

end

function a = mergelabs( a, b )

missing_cats = setdiff( unique(b.categories), unique(a.categories) );

for i = 1:numel(missing_cats)
  
  to_add = full_fields( b, missing_cats{i} );
  
  if ( any(contains(a, to_add)) ), continue; end
  
  a = add_field( a, missing_cats{i}, to_add );
end

end