function outs = bin_look_events_by_stim(look_ahead, files_containing)

if ( nargin < 2 )
  files_containing = [];
end

stim_p = bfw.get_intermediate_directory( 'stim' );
unified_p = bfw.get_intermediate_directory( 'unified' );
aligned_p = bfw.get_intermediate_directory( 'aligned' );
events_p = bfw.get_intermediate_directory( 'events_per_day' );
bounds_p = bfw.get_intermediate_directory( 'bounds' );
fix_p = bfw.get_intermediate_directory( 'fixations' );

mats = bfw.require_intermediate_mats( [], stim_p, files_containing );

outs = struct();
outs.n_fix = Container();
outs.fix_dur = Container();
outs.total_dur = Container();
outs.p_look_back = Container();
outs.p_in_bounds = Container();
outs.vel = Container();
outs.amp_vel = Container();
outs.fix = Container();

for i = 1:numel(mats)

stim_file = shared_utils.io.fload( mats{i} );

un_filename = stim_file.unified_filename;

un_file = shared_utils.io.fload( fullfile(unified_p, un_filename) );
events_file = shared_utils.io.fload( fullfile(events_p, un_filename) );
bounds_file = shared_utils.io.fload( fullfile(bounds_p, un_filename) );
aligned_file = shared_utils.io.fload( fullfile(aligned_p, un_filename) );
fix_file = shared_utils.io.fload( fullfile(fix_p, un_filename) );

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

%
% labs
%

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
% fix amps vs. vels
%

fix_la = look_ahead;
fix_starts = fix_file.m1.time( fix_file.m1.start_indices );
fix_stops = fix_file.m1.time( fix_file.m1.stop_indices );

[stim_fix, stim_end_fix] = bin_fixations( fix_starts, fix_stops ...
  , stim_file.stimulation_times, fix_la, mat_time, plex_time );
[sham_fix, sham_end_fix] = bin_fixations( fix_starts, fix_stops ...
  , stim_file.sham_times, fix_la, mat_time, plex_time );

[stim_amps, stim_vels] = fix_amplitude( stim_fix, stim_end_fix, aligned_file.m1.position, mat_time );
[sham_amps, sham_vels] = fix_amplitude( sham_fix, sham_end_fix, aligned_file.m1.position, mat_time );

va_labs = set_field( ib_labs, 'meas_type', 'amp_vel' );

va_stim_means = Container( [stim_amps(:), stim_vels(:)], va_labs );
va_sham_means = Container( [sham_amps(:), sham_vels(:)] ...
  , set_field(va_labs, 'stim_type', 'sham') );

outs.amp_vel = extend( outs.amp_vel, va_stim_means, va_sham_means );

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
% fix psth
%
f_lb = -1e3;
f_la = 2e3;

[fpsth_stim, fix_t] = fix_psth( fix_file.m1.is_fixation, stim_file.stimulation_times, mat_time, plex_time, f_lb, f_la );
fpsth_sham = fix_psth( fix_file.m1.is_fixation, stim_file.sham_times, mat_time, plex_time, f_lb, f_la );

fix_labs = set_field( ib_labs, 'meas_type', 'is_fixation' );
fix_labs = set_field( fix_labs, 'look_ahead', sprintf('look_ahead__%0.3f', f_la/1e3) );

fpsth_stim = Container( fpsth_stim, fix_labs );
fpsth_sham = Container( fpsth_sham, set_field(fix_labs, 'stim_type', 'sham') );

outs.fix = extend( outs.fix, fpsth_stim, fpsth_sham );
outs.fix_t = fix_t;


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
  
  lb = -1;
  la = 5;
  bw = 0.1;
  ss = 0.1;

%   lb = -0.5;
%   la = 5;
%   bw = 0.5;
%   ss = 0.1;

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

function [psth, t] = fix_psth(is_fix, events, mat_time, plex_time, f_lb, f_la)

first_t = find( plex_time > 0, 1, 'first' );
plex_time = plex_time(first_t:end);
mat_time = mat_time(first_t:end);
is_fix = is_fix(first_t:end);

t = f_lb:f_la;

psth = false( numel(events), numel(t) );

for i = 1:numel(events)
  [~, plex_i] = min( abs(plex_time - events(i)) );
  mat_t = mat_time(plex_i);
  [~, mat_i] = min( abs(mat_time - mat_t) );
  
  start = mat_i + f_lb;
  stop = mat_i + f_la;
  
  psth(i, :) = is_fix(start:stop);
end

psth = sum(psth, 1) / size(psth, 1);

end

function [amps, vels] = fix_amplitude(fix_starts, fix_stops, pos, mat_t)

filt_order = 4;
frame_len = 21;

x = pos(1, :);
y = pos(2, :);

x = sgolayfilt( x, filt_order, frame_len );
y = sgolayfilt( y, filt_order, frame_len );

amps = nan( 1, numel(fix_starts) );
vels = nan( size(amps) );

for i = 1:numel(fix_starts)
  starts = fix_starts{i};
  stops = fix_stops{i};
  
  tmp_amps = nan( 1, numel(starts)-1 );
  tmp_vels = nan( size(tmp_amps)-1 );
  
  if ( numel(starts) < 2 )
    continue;
  end
  
  for j = 1:numel(starts)-1
    start0 = starts(j);
    stop0 = stops(j);
    start1 = starts(j+1);
    stop1 = stops(j+1);

    [~, start0_i] = min( abs(mat_t - start0) );
    [~, stop0_i] = min( abs(mat_t - stop0) );
    [~, start1_i] = min( abs(mat_t - start1) );
    [~, stop1_i] = min( abs(mat_t - stop1) );
    
    x_avg0 = nanmean( x(start0_i:stop0_i) );
    y_avg0 = nanmean( y(start0_i:stop0_i) );
    x_avg1 = nanmean( x(start1_i:stop1_i) );
    y_avg1 = nanmean( y(start1_i:stop1_i) );
    
%     xamp = abs( x(start1_i) - x(stop0_i) );
%     yamp = abs( y(start1_i) - y(stop0_i) );

    xamp = abs( x_avg1 - x_avg0 );
    yamp = abs( y_avg1 - y_avg0 );
    
    subset_x = x(stop0_i+1:start1_i);
    subset_y = y(stop0_i+1:start1_i);
    
    x_peakvel = max( abs(diff(subset_x)) ) * 1e3;
    y_peakvel = max( abs(diff(subset_y)) ) * 1e3;
    
    tmp_amps(j) = (xamp + yamp) / 2;
    tmp_vels(j) = (x_peakvel + y_peakvel) / 2;
  end
  
  %   first valid saccade
  use_ind = find( ~isnan(tmp_amps) & ~isnan(tmp_vels), 1, 'first' );
  
  if ( isempty(use_ind) )
    use_ind = 1;
  end
  
  amps(i) = tmp_amps(use_ind);
  vels(i) = tmp_vels(use_ind);
  
  continue;
  
  %
  % old
  %
  
  for j = 1:numel(starts)-1
%   for j = 1
  
    start0 = starts(j);
    stop0 = stops(j);
    start1 = starts(j+1);
    stop1 = stops(j+1);

    [~, start0_i] = min( abs(mat_t - start0) );
    [~, stop0_i] = min( abs(mat_t - stop0) );
    [~, start1_i] = min( abs(mat_t - start1) );
    [~, stop1_i] = min( abs(mat_t - stop1) );

    x_avg0 = nanmean( x(start0_i:stop0_i) );
    y_avg0 = nanmean( y(start0_i:stop0_i) );
    x_avg1 = nanmean( x(start1_i:stop1_i) );
    y_avg1 = nanmean( y(start1_i:stop1_i) );
    
    diff_t = stop1 - stop0;
    
    xamp = abs( x_avg1 - x_avg0 );
    yamp = abs( y_avg1 - y_avg0 );
    
    xvel = xamp / diff_t;
    yvel = yamp / diff_t;
    
    tmp_amps(j) = (xamp + yamp) / 2;
    tmp_vels(j) = (xvel + yvel) / 2;
  end
  
  amps(i) = nanmean( tmp_amps );
  vels(i) = nanmean( tmp_vels );

%   amps(i) = max( tmp_amps );
%   vels(i) = max( tmp_vels );
end

end

function [fix, end_fix] = bin_fixations(fix_starts, fix_stops, event_times, la, mat_time, plex_time)

first_t = find( plex_time > 0, 1, 'first' );
plex_t = plex_time(first_t:end);
mat_t = mat_time(first_t:end);

fix = cell( 1, numel(event_times) );
end_fix = cell( size(fix) );

for i = 1:numel(event_times)
  et = event_times(i);
  [~, I] = min( abs(plex_t - et) );
  mat_et = mat_t(I);
  ind = fix_starts >= mat_et & fix_starts < mat_et + la;
  fix{i} = fix_starts(ind);
  end_fix{i} = fix_stops(ind);
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