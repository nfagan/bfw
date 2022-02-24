%%

event_subdir = 'remade_032921';

inputs = { 'raw_events/remade_032921', 'aligned_raw_samples/position', 'calibration_coordinates', 'meta', 'rois' };

args = struct();
% args.files_containing = { '02092018' };

[~, runner] = bfw.get_params_and_loop_runner( inputs, '', bfw.get_common_make_defaults(), {args} );
runner.convert_to_non_saving_with_output();
runner.is_parallel = true;

res = runner.run( @gaze_follow_angle_sim_from_files, event_subdir ...
  , 'center_type', 'eyes' ...
  , 'flip_y', true ...
  , 'exclude_sequence_of_target_events', true ...
  , 'num_evts_look_ahead', 1 ...
  , 'reject_if_m2_in_eyes', true ...
  , 'reject_if_m2_in_eyes_duration', 500 ...
);
gf_outs = shared_utils.pipeline.extract_outputs_from_results( res );
gf_outs = shared_utils.struct.soa( gf_outs );

%%

hist( gf_outs.gf_sim, 200 );
xlabel( 'M1 direction dot M2 direction' );

%%

is_gf_event = gf_outs.gf_sim >= cos( deg2rad(45) ) & gf_outs.m1_evt_iei <= 500;
gf_event_ind = find( is_gf_event );
gf_event_labs = gf_outs.gf_labels(gf_event_ind);
[freq_labs, I] = keepeach( gf_event_labs', 'session' );
freqs = cellfun( @numel, I );

pl = plotlabeled.make_common();
axs = pl.bar( freqs, freq_labs, {}, {}, {} );

%%

events = bfw_gather_events( 'event_subdir', event_subdir, 'require_stim_meta', false );
spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes' );
bfw.apply_new_cell_id_labels( spikes.labels, bfw_load_cell_id_matrix() );

%%  events split by quadrant

[gf_I, gf_C] = findall( gf_outs.gf_labels, {'unified_filename', 'session'} );
evt_I = bfw.find_combinations( events.labels, gf_C );

evt_sets = cell( size(evt_I) );
evt_set_labels = cell( size(evt_I) );
evt_set_durs = cell( size(evt_sets) );

four_quadrants = true;
if ( four_quadrants )
  qds = { [1, 0], [0, 1], [-1, 0], [0, -1] };
  qd_labels = { 'm2-right', 'm2-up', 'm2-left', 'm2-down' };
  qd_theta = deg2rad( 90 );
else
  qds = { [1, 0], [-1, 0] };
  qd_labels = { 'm2-right', 'm2-left' };
  qd_theta = deg2rad( 180 );
end

start_ts = bfw.event_column( events, 'start_time' );
stop_ts = bfw.event_column( events, 'stop_time' );
event_durs = stop_ts - start_ts;

accept_theta = deg2rad( 22.5 );
align_to_eye_end = true;

parfor i = 1:numel(evt_I)
  shared_utils.general.progress( i, numel(evt_I) );
  
  [evt_sets{i}, evt_set_labels{i}] = make_events_split_by_m2_quadrants( ...
    gf_outs, events, gf_I{i}, evt_I{i} ...
    , 'quadrant_theta', qd_theta ...
    , 'accept_theta', accept_theta ...
    , 'reject_theta', deg2rad(90) ...
    , 'reject_within_opposite_m2_cone_theta', deg2rad(180) ...
    , 'iei_thresh', 1000 ... % ms
    , 'align_to_eye_end', align_to_eye_end ...
    , 'match_to_m2_cone', true ...
    , 'exclude_target_events', true ...
    , 'reject_within_opposite_m2_cone', false ...
    , 'quadrant_dirs', qds ...
    , 'quadrant_dir_labels', qd_labels ...
    , 'by_quadrant', false ...
  );

  curr_eye_evti = evt_I{i}(gf_outs.targ_mask(gf_I{i}));
  evt_set_durs{i} = event_durs(curr_eye_evti);
end

evts = vertcat( evt_sets{:} );
evt_durs = vertcat( evt_set_durs{:} );
evt_labels = vertcat( fcat, evt_set_labels{:} );

%%

mask = find( evt_labels, {'gf-event', 'null-event'} );
[cts, count_labs] = counts_of( evt_labels', {'session', 'event-type'}, {'m2-quadrant'}, mask );
pl = plotlabeled.make_common();
pl.x_order = { 'm2-left', 'm2-up', 'm2-right', 'm2-down' };
axs = pl.bar( cts, count_labs, {'m2-quadrant'}, {'event-type'}, {} );

if ( true )
  save_p = fullfile( bfw.dataroot(conf), 'plots/gaze_following/event_counts', dsp3.datedir );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, count_labs, 'm2-quadrant' );
end

%%

[evt_I, evt_C] = findall( evt_labels, {'unified_filename', 'session'} );
spk_I = bfw.find_combinations( spikes.labels, evt_C(2, :) );

dst_labs = cell( size(evt_I) );
dst_psth = cell( size(dst_labs) );
bin_ts = cell( size(dst_labs) );

parfor i = 1:numel(evt_I)
  shared_utils.general.progress( i, numel(evt_I) );
  ei = evt_I{i};
  si = spk_I{i};
  [dst_psth{i}, dst_labs{i}, bin_ts{i}] = make_psth( evts, evt_labels, spikes, ei, si ...
    , 'min_t', -1 ...
    , 'max_t', 1 ...
    , 'bin_width', 0.01 ...
  );
end

psth = vertcat( dst_psth{:} );
psth_labels = vertcat( fcat, dst_labs{:} );
assert_ispair( psth, psth_labels );

%%  stat

over_time = false;

t_ind = bin_ts{1} >= -0.250 & bin_ts{1} <= 0.0;
if ( over_time )
  mean_t_psth = psth;
else
  mean_t_psth = nanmean( psth(:, t_ind), 2 );
end

[unit_labs, unit_I] = keepeach( psth_labels', {'unit_uuid'} );
[prop_labs, reg_I] = keepeach( unit_labs', 'region' );

ps = nan( numel(unit_I), size(mean_t_psth, 2) );
props = nan( numel(reg_I), size(ps, 2) );
for t = 1:size(ps, 2)
  for i = 1:numel(unit_I)
    gf_ind = find( psth_labels, 'gf-event', unit_I{i} );
    null_ind = find( psth_labels, 'null-event', unit_I{i} );
    ps(i, t) = ranksum( mean_t_psth(gf_ind, t), mean_t_psth(null_ind, t) );
  end
  props(:, t) = cellfun( @(x) sum(ps(x, t) < 0.05) / numel(x), reg_I );
end

%%

if ( over_time )
  is_sig = ps(:, t_ind) < 0.05;
  has_sig = false( rows(is_sig), 1 );
  for i = 1:rows(is_sig)
    [~, durs] = shared_utils.logical.find_islands( is_sig(i, :) );
    has_sig(i) = any( durs >= 2 );
  end
  % has_sig = any( ps(:, t_ind) < 0.05, 2 );
  p_sig = cellfun( @(x) sum(has_sig(x))/numel(x), reg_I );
else  
  p_sig = cellfun( @(x) sum(ps(x) < 0.05)/numel(x), reg_I );
  
  c_s = cellfun( @(x) sum(ps(x) < 0.05), reg_I );
  c_ns = cellfun( @(x) sum(ps(x) >= 0.05), reg_I );
  c_l = repset( addcat(prop_labs', 'sig'), 'sig', {'sig-true', 'sig-false'} );
  cs = [ c_s; c_ns ];
  [chi2_info, chi2_labels] = dsp3.chi2_tabular_frequencies( cs, c_l', {}, 'region', 'sig' );
end

%%

pl = plotlabeled.make_common();
pl.x = bin_ts{1};
axs = pl.lines( props, prop_labs, 'region', {} );

%%

pl = plotlabeled.make_common();
axs = pl.bar( p_sig, prop_labs, 'region', {}, {} );

if ( true )
  save_
end

%%

[gf_I, gf_C] = findall( gf_outs.gf_labels, {'unified_filename', 'session'} );
rest_I = bfw.find_combinations( gf_outs.rest_labels, gf_C );
evt_I = bfw.find_combinations( events.labels, gf_C );
spk_I = bfw.find_combinations( spikes.labels, gf_C(2, :) );

evt_start = bfw.event_column( events, 'start_time' );
evt_end = bfw.event_column( events, 'stop_time' );

min_t = -1;
max_t = 1;
bin_width = 0.05;
align_to_eye_end = true;

dst_labs = cell( size(evt_I) );
dst_psth = cell( size(dst_labs) );
bin_ts = cell( size(dst_labs) );

iei_thresh = 500;
is_gf_event = @(gf_sim, m1_evt_iei) gf_sim >= cos( deg2rad(45) ) & m1_evt_iei <= iei_thresh;
is_non_gf_event = @(gf_sim, m1_evt_iei) gf_sim < cos(deg2rad(90)) & m1_evt_iei <= iei_thresh;

accept_theta = deg2rad( 45 );
reject_theta = deg2rad( 90 );

split_by_quadrant = true;

parfor i = 1:numel(evt_I)
  shared_utils.general.progress( i, numel(evt_I) );
  
  gi = gf_I{i};
  ri = rest_I{i};
  ei = evt_I{i};
  si = spk_I{i};
  
  if ( split_by_quadrant )
    [sub_psth, sub_labels, bin_ts{i}] = psth_split_by_m2_quadrant( ...
      gf_outs, events, spikes, gi, ei, si ...
      , 'accept_theta', accept_theta ...
      , 'reject_theta', reject_theta ...
      , 'min_t', min_t ...
      , 'max_t', max_t ...
      , 'bin_width', bin_width ...
      , 'iei_thresh', iei_thresh ...
      , 'align_to_eye_end', align_to_eye_end ...
    );
  else
    src_gf_gf = gf_outs.next_m1_evt_ind(gi);
    gf_sim = gf_outs.gf_sim(gi);
    m1_evt_iei = gf_outs.m1_evt_iei(gi);
    % Keep only those events meeting the criteria above
    meets_gf_crit = is_gf_event( gf_sim, m1_evt_iei );  
    non_nan_gf = ~isnan( src_gf_gf );
    fails_gf_crit = non_nan_gf & is_non_gf_event( gf_sim, m1_evt_iei );
    gf_evt_ind = find( meets_gf_crit & non_nan_gf );
    gf_gf = src_gf_gf(gf_evt_ind);
    assert( ~any(fails_gf_crit & meets_gf_crit) );

    gf_rest = gf_outs.rest_mask(ri);
    if ( false )
      null_subset = setdiff( gf_rest, gf_gf );  % remaining non gaze following m1 events.
    end

    if ( align_to_eye_end )
      targ_subset = gf_outs.targ_mask(gi(gf_evt_ind));
      null_subset = gf_outs.targ_mask(gi(fails_gf_crit));
    else
      targ_subset = gf_gf;
      null_subset = src_gf_gf(fails_gf_crit);
    end
  
    null_ei = ei(null_subset);
    targ_ei = ei(targ_subset);

    if ( align_to_eye_end )
      targ_ts = evt_end(targ_ei);
      null_ts = evt_end(null_ei);
    else
      targ_ts = evt_start(targ_ei);
      null_ts = evt_start(null_ei);
    end

    assert( all(strcmp(combs(events.labels, 'looks_by', null_ei), {'m1'})) );
    assert( all(strcmp(combs(events.labels, 'looks_by', targ_ei), {'m1'})) );
    if ( align_to_eye_end )
      assert( all(strcmp(combs(events.labels, 'roi', targ_ei), {'eyes_nf'})) );
      assert( all(strcmp(combs(events.labels, 'roi', null_ei), {'eyes_nf'})) );
    end

    null_labels = make_null_event_labels( events.labels, null_ei );
    targ_labels = make_gf_event_labels( events.labels, targ_ei );

    [null_psth, null_psth_labels, bin_ts{i}] = gf_psth( ...
      spikes, si, null_ts, null_labels, min_t, max_t, bin_width );
    [targ_psth, targ_psth_labels] = gf_psth( ...
      spikes, si, targ_ts, targ_labels, min_t, max_t, bin_width );

    sub_labels = append( null_psth_labels, targ_psth_labels );
    sub_psth = [ null_psth; targ_psth ];
    
  end
  
  assert_ispair( sub_psth, sub_labels );
  dst_psth{i} = sub_psth;
  dst_labs{i} = sub_labels;
end

psth = vertcat( dst_psth{:} );
psth_labels = vertcat( fcat, dst_labs{:} );
assert_ispair( psth, psth_labels );

%%  quadrant psth

% plt_mask = find( psth_labels, ref(combs(psth_labels, 'unit_uuid'), '()', 5) );
% plt_mask = find( psth_labels, 'unit_uuid__115' );
plt_mask = rowmask( psth_labels );
[unit_I, unit_C] = findall( psth_labels, {'unit_uuid', 'region'}, plt_mask );

ts = bin_ts{1};

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  pl = plotlabeled.make_common();
  pl.x = ts;
  pl.add_errors = true;
  pl.add_smoothing = false;
  pl.smooth_func = @(x) smoothdata(x, 'smoothingfactor', 0.75);
  pl.group_order = { 'gf-event', 'null-event', 'control-event' };
  pl.panel_order = { 'm2-left', 'm2-right', 'm2-up', 'm2-down' };
  pl.color_func = @(n) [[1, 0, 0]; [0, 0, 1]];
  
  ui = unit_I{i};
  fr_subset = psth(ui, :) ./ 1 / bin_width;
  lab_subset = prune( psth_labels(ui) );
  axs = pl.lines( fr_subset, lab_subset, 'event-type', {'region', 'unit_uuid', 'm2-quadrant'} );
  hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, 0 );
  
  if ( true )
    save_p = fullfile( bfw.dataroot(conf), 'plots/gaze_following/quadrant_psth', dsp3.datedir );
    save_p = fullfile( save_p, unit_C{2, i} );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, lab_subset, {'unit_uuid'} );
  end
end

%%

% plt_mask = find( psth_labels, ref(combs(psth_labels, 'unit_uuid'), '()', 5) );
plt_mask = find( psth_labels, 'unit_uuid__115' );
% plt_mask = rowmask( psth_labels );
[unit_I, unit_C] = findall( psth_labels, {'unit_uuid', 'region'}, plt_mask );

perm_test = true;
perm_iters = 1e3;
perm_test_func = @ranksum;
ts = bin_ts{1};
match_n = true;

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  pl = plotlabeled.make_common();
  pl.x = ts;
  pl.add_errors = true;
  pl.add_smoothing = false;
  pl.smooth_func = @(x) smoothdata(x, 'smoothingfactor', 0.75);
  
  ui = unit_I{i};
  nulli = find( psth_labels, 'null-event', ui );
  targi = find( psth_labels, 'gf-event', ui );
  
  if ( perm_test )
    ps = perm_test_n_match( psth, targi, nulli, perm_iters, perm_test_func, true );
    p_sig = 1 - (sum(ps < 0.05, 1) / size(ps, 1));
    is_sig = p_sig < 0.05;
  else
    is_sig = false( 1, size(psth, 2) );
  end
  
  if ( match_n )
    if ( numel(nulli) > numel(targi) )
      nulli = sort( nulli(randperm(numel(nulli), numel(targi))) );
    elseif ( numel(targi) > numel(nulli) )
      targi = sort( targi(randperm(numel(targi), numel(nulli))) );
    end
    ui = [ nulli; targi ];
  end
  
  fr_subset = psth(ui, :) ./ 1 / bin_width;
  lab_subset = prune( psth_labels(ui) );
  axs = pl.lines( fr_subset, lab_subset, 'event-type', {'region', 'unit_uuid'} );
  hold( axs, 'on' );
  shared_utils.plot.add_vertical_lines( axs, 0 );
  
  sig_inds = find( is_sig );
  for j = 1:numel(sig_inds)
    plot( axs(1), ts(sig_inds(j)), max(get(axs(1), 'ylim')), 'k*' );
  end
  
  if ( true )
    save_p = fullfile( bfw.dataroot(conf), 'plots/gaze_following/psth', dsp3.datedir );
    save_p = fullfile( save_p, unit_C{2, i} );
    shared_utils.plot.fullscreen( gcf );
    dsp3.req_savefig( gcf, save_p, lab_subset, {'unit_uuid'} );
  end
end

%%

function test_out = perm_test_n_match(data, ai, bi, iters, test_func, un_output)

n_sample = min( numel(ai), numel(bi) );

if ( un_output )
  test_out = nan( iters, size(data, 2) );
else
  test_out = cell( iters, size(data, 2) );
end

for i = 1:iters
  sai = ai(randperm(numel(ai), n_sample));
  sbi = bi(randperm(numel(bi), n_sample));
  da = data(sai, :);
  db = data(sbi, :);
  for j = 1:size(data, 2)
    out = test_func( da(:, j), db(:, j) );
    if ( un_output )
      test_out(i, j) = out;
    else
      test_out{i, j} = out;
    end
  end
end

end

function out = gaze_follow_angle_sim_from_files(files, event_subdir, varargin)

defaults = struct();
defaults.center_type = '';
defaults.flip_y = [];
defaults.exclude_sequence_of_target_events = [];
defaults.num_evts_look_ahead = [];
defaults.reject_if_m2_in_eyes = [];
defaults.reject_if_m2_in_eyes_duration = [];
params = shared_utils.general.parsestruct( defaults, varargin );

center_type = params.center_type; 
flip_y = params.flip_y;
exclude_sequence_of_target_events = params.exclude_sequence_of_target_events;
num_evts_look_ahead = params.num_evts_look_ahead;

evts = files(event_subdir);
pos = files('position');
coords = files('calibration_coordinates');
meta = files('meta');
rois = files('rois');

evti = [ bfw.event_column(evts, 'start_index') ...
       , bfw.event_column(evts, 'stop_index') ];
evt_labels = fcat.from( evts );

targ_mask = find( evt_labels, {'m1', 'eyes_nf'} );
rest_mask = find( evt_labels, 'm1' );

targ_evti = evti(targ_mask, :);
rest_evti = evti(rest_mask, :);

keep_targ_mask = true( size(targ_mask) );
if ( exclude_sequence_of_target_events )
  for i = 1:size(targ_evti, 1)
    evt_s = targ_evti(i, 1);
    next_evt_rel = rest_evti(:, 1) - evt_s;
    poss_next_ind = find( next_evt_rel > 0 );
    [~, first_next_ind] = min( next_evt_rel(poss_next_ind) );
    next_ind = poss_next_ind(first_next_ind);
    next_ind_rest = rest_mask(next_ind);
    if ( ismember(next_ind_rest, targ_mask) )
      % next event is also a target event.
      keep_targ_mask(i) = false;
    end
  end
end

targ_mask = targ_mask(keep_targ_mask);
targ_evti = targ_evti(keep_targ_mask, :);

if ( params.reject_if_m2_in_eyes )
  eye_check_dur = params.reject_if_m2_in_eyes_duration;
  eye_check_end = targ_evti(:, 2);  % end of eye event.
  eye_check_start = max( ones(size(eye_check_end)), eye_check_end - eye_check_dur );
  m2_in_eyes = m2_was_in_eyes( eye_check_start, eye_check_end, pos.m2, rois.m2.rects('eyes_nf') );
  
  targ_mask(m2_in_eyes) = [];
  targ_evti(m2_in_eyes, :) = [];
end

switch ( center_type )
  case 'eyes'
    center_m1 = shared_utils.rect.center( rois.m1.rects('eyes_nf') );
    center_m2 = shared_utils.rect.center( rois.m2.rects('eyes_nf') );
  case 'screen'
    center_m1 = shared_utils.rect.center( coords.m1 );
    center_m2 = shared_utils.rect.center( coords.m2 );
  otherwise
    error( 'Unrecognized center type "%s".', center_type );
end

pos_m1 = pos.m1 - center_m1(:);
pos_m2 = pos.m2 - center_m2(:);

if ( flip_y )
  pos_m1(2, :) = -pos_m1(2, :);
  pos_m2(2, :) = -pos_m2(2, :);
end

[gf_sim, pos_info] = gaze_follow_angle_sim( pos_m1, pos_m2, targ_evti, rest_evti, num_evts_look_ahead );
has_evt = ~isnan( pos_info.next_m1_evt_ind );
pos_info.next_m1_evt_ind(has_evt) = rest_mask(pos_info.next_m1_evt_ind(has_evt));

assert( all(strcmp(combs(evt_labels, 'looks_by', rest_mask), {'m1'})) );

out = pos_info;
out.gf_sim = gf_sim;
out.rest_mask = rest_mask;
out.targ_mask = targ_mask;
out.gf_labels = join( prune(evt_labels(targ_mask)), bfw.struct2fcat(meta) );
out.rest_labels = join( prune(evt_labels(rest_mask)), bfw.struct2fcat(meta) );

end

function tf = m2_was_in_eyes(event_starts, event_stops, m2_pos, eye_roi)

assert( numel(event_starts) == numel(event_stops) && ...
  (isempty(event_starts) || iscolumn(event_starts)) );
tf = false( numel(event_starts), 1 );
for i = 1:numel(event_starts)
  e_range = event_starts(i):event_stops(i);
  evt_pos = m2_pos(:, e_range);
  evt_ib = shared_utils.rect.inside( eye_roi, evt_pos(1, :), evt_pos(2, :) );
  tf(i) = any( evt_ib );
end

end

function [gf_sim, pos_info] = gaze_follow_angle_sim(pos_m1, pos_m2, targ_evts, rest_evts, num_evts_look_ahead)

pos_info = bfw_gf.gaze_following_positions( ...
    targ_evts, rest_evts ...
  , pos_m1, pos_m2 ...
  , num_evts_look_ahead ...
);

[m1_dirs, m2_dirs] = gaze_following_behavior( pos_info.next_m1_pos, pos_info.m2_pos );

gf_sim = nan( size(m1_dirs, 1), size(m1_dirs, 3) );
for i = 1:size(m1_dirs, 3)
  gf_sim(:, i) = dot( squeeze(m1_dirs(:, :, i)), m2_dirs, 2 );
end

% gf_sim = dot( m1_dirs, m2_dirs, 2 );
pos_info.m1_dirs = m1_dirs;
pos_info.m2_dirs = m2_dirs;

end

function [m1_dirs, m2_dirs] = gaze_following_behavior(m1_gf_pos, m2_gf_pos)

m1_dirs = nan( size(m1_gf_pos) );
m2_dirs = nan( size(m2_gf_pos) );

for i = 1:size(m1_gf_pos, 3)
  m1_pos_evt = squeeze( m1_gf_pos(:, :, i) );
  [m1_dirs(:, :, i), m2_dirs] = bfw_gf.gaze_following_behavior( m1_pos_evt, m2_gf_pos );
end

end

function labs = make_event_labels(evt_labels, mask, event_type)
labs = append( fcat, evt_labels, mask );
addcat( labs, 'event-type' );
guard_empty( labs, @(l) setcat(l, 'event-type', event_type) );
end

function null_labels = make_null_event_labels(evt_labels, null_ei)
null_labels = make_event_labels( evt_labels, null_ei, 'null-event' );
end

function targ_labels = make_gf_event_labels(evt_labels, targ_ei)
targ_labels = make_event_labels( evt_labels, targ_ei, 'gf-event' );
end

function targ_labels = make_control_event_labels(evt_labels, targ_ei)
targ_labels = make_event_labels( evt_labels, targ_ei, 'control-event' );
end

function [psth, labels, t] = gf_psth(spikes, si, evt_ts, evt_labels ...
  , min_t, max_t, bin_width)

assert_ispair( evt_ts, evt_labels );

psth = [];
labels = fcat();
t = [];

for i = 1:numel(si)
  unit_ts = spikes.units(si(i)).times;
  unit_labs = spikes.labels(si(i));
  
  merge( evt_labels, unit_labs );
  append( labels, evt_labels );
  
  [unit_psth, t] = bfw.trial_psth( unit_ts(:), evt_ts(:), min_t, max_t, bin_width );
  psth = [ psth; unit_psth ];
end

end

function [evt_sets, label_sets] = make_events_split_by_m2_quadrants(gf_outs, events, gi, ei, varargin)

defaults = struct();
defaults.quadrant_theta = [];
defaults.accept_theta = [];
defaults.reject_theta = [];
defaults.reject_within_opposite_m2_cone_theta = [];
defaults.iei_thresh = [];
defaults.align_to_eye_end = [];
defaults.match_to_m2_cone = [];
defaults.exclude_target_events = [];
defaults.reject_within_opposite_m2_cone = [];
defaults.quadrant_dirs = { [1, 0], [0, 1], [-1, 0], [0, -1] };
defaults.quadrant_dir_labels = { 'm2-right', 'm2-up', 'm2-left', 'm2-down' };
defaults.by_quadrant = [];

params = shared_utils.general.parsestruct( defaults, varargin );

by_quadrant = params.by_quadrant;

accept_theta = params.accept_theta * 0.5; % +/-
quadrant_theta = params.quadrant_theta * 0.5;
reject_theta = params.reject_theta * 0.5;
reject_within_opposite_m2_cone_theta = params.reject_within_opposite_m2_cone_theta * 0.5;

iei_thresh = params.iei_thresh;
align_to_eye_end = params.align_to_eye_end;
match_to_m2_cone = params.match_to_m2_cone;
reject_within_opposite_m2_cone = params.reject_within_opposite_m2_cone;
exclude_target_events = params.exclude_target_events;

m1_dirs = gf_outs.m1_dirs(gi, :, :);
m2_dirs = gf_outs.m2_dirs(gi, :);
evt_iei = gf_outs.m1_evt_iei(gi, :);
next_evti = gf_outs.next_m1_evt_ind(gi, :);
curr_eye_evti = gf_outs.targ_mask(gi);
next_evt_is_target = ismember( next_evti, curr_eye_evti );

if ( by_quadrant )
  quadrant_dirs = params.quadrant_dirs;
  quadrant_dir_labels = params.quadrant_dir_labels;
else
  quadrant_dirs = { [0, 1] };
  quadrant_dir_labels = { 'm2-any-direction' };
end

evt_sets = [];
label_sets = fcat();

evt_start = bfw.event_column( events, 'start_time' );
evt_end = bfw.event_column( events, 'stop_time' );

for qi = 1:numel(quadrant_dirs)
  qd = quadrant_dirs{qi};
  target_dirs = repmat( qd, rows(m2_dirs), 1 );
  m2_dot_t = dot( m2_dirs, target_dirs, 2 );
  m1_dot_t = dot_m1_m2( m1_dirs, target_dirs );
  m1_dot_m2 = dot_m1_m2( m1_dirs, m2_dirs );
  m1_dot_opp_m2 = dot_m1_m2( m1_dirs, -m2_dirs );
  
  valid_m2_dirs = ~any( isnan(m2_dirs), 2 );
  valid_m1_dirs = false( size(m1_dot_m2) );

  if ( by_quadrant )
    m2_within_cone = accept_within_cone( m2_dot_t, evt_iei(:, 1), quadrant_theta, inf );
  else
    m2_within_cone = valid_m2_dirs;
  end
  
  m1_within_cone = false( size(m1_dot_m2) );
  m1_outside_cone = false( size(m1_dot_m2) );
  
  for j = 1:size(m1_within_cone, 2)
    valid_m1_dirs(:, j) = ~any( isnan(m1_dirs(:, :, j)), 2 );
    if ( match_to_m2_cone )
      m1_within_cone(:, j) = accept_within_cone(...
        m1_dot_m2(:, j), evt_iei(:, j), accept_theta, iei_thresh );
      if ( reject_within_opposite_m2_cone )
        m1_outside_cone(:, j) = accept_within_cone(...
          m1_dot_opp_m2(:, j), evt_iei(:, j), reject_within_opposite_m2_cone_theta, iei_thresh );
      else
        m1_outside_cone(:, j) = reject_outside_cone(...
          m1_dot_m2(:, j), evt_iei(:, j), reject_theta, iei_thresh );
      end
    else
      m1_within_cone(:, j) = accept_within_cone( m1_dot_t(:, j), evt_iei(:, j), quadrant_theta, iei_thresh );
      m1_outside_cone(:, j) = reject_outside_cone( m1_dot_t(:, j), evt_iei(:, j), reject_theta, iei_thresh );
    end 
    if ( exclude_target_events )
      m1_within_cone(:, j) = m1_within_cone(:, j) & ~next_evt_is_target(:, j);
    end
  end

  valid_dirs = valid_m2_dirs & any( valid_m1_dirs, 2 );
  m1_within_cone = any( m1_within_cone, 2 );
  
  if ( reject_within_opposite_m2_cone )
    m1_outside_cone = all( m1_outside_cone, 2 );
  else
    m1_outside_cone = ~m1_within_cone;
  end
  
  m1_true_gf = m1_within_cone & m2_within_cone & valid_dirs;
  m1_null_gf = m2_within_cone & m1_outside_cone & valid_dirs;
  m1_control_gf = ~m2_within_cone & m1_within_cone & valid_dirs;

  assert( sum(m1_true_gf & m1_null_gf) == 0 && ...
          sum(m1_null_gf & m1_control_gf) == 0 && ...
          sum(m1_control_gf & m1_true_gf) == 0 );

  if ( align_to_eye_end )
    evt_inds = curr_eye_evti;
    evt_ts = evt_end;
  else
    evt_inds = next_evti;
    evt_ts = evt_start;
  end

  null_ei = ei(evt_inds(m1_null_gf));
  targ_ei = ei(evt_inds(m1_true_gf));
  ctrl_ei = ei(evt_inds(m1_control_gf));

  null_ts = evt_ts(null_ei);
  targ_ts = evt_ts(targ_ei);
  ctrl_ts = evt_ts(ctrl_ei);

  null_labels = make_null_event_labels( events.labels, null_ei );
  targ_labels = make_gf_event_labels( events.labels, targ_ei );
  ctrl_labels = make_control_event_labels( events.labels, ctrl_ei );

  tmp_labels = extend( null_labels, targ_labels, ctrl_labels );
  tmp_evts = [ null_ts; targ_ts; ctrl_ts ];
  assert_ispair( tmp_evts, tmp_labels );

  if ( ~isempty(tmp_labels) )
    addsetcat( tmp_labels, 'm2-quadrant', quadrant_dir_labels{qi} );
    append( label_sets, tmp_labels );
    evt_sets = [ evt_sets; tmp_evts ];
  else
    assert( isempty(tmp_evts) );
  end
end

assert_ispair( evt_sets, label_sets );

end

function ct = dot_m1_m2(m1_dirs, m2_dirs)

assert( ismatrix(m2_dirs) && size(m2_dirs, 2) == 2 );
assert( size(m1_dirs, 2) == 2 && size(m1_dirs, 1) == size(m2_dirs, 1) );

ct = nan( size(m1_dirs, 1), size(m1_dirs, 3) );
for i = 1:size(m1_dirs, 3)
  ct(:, i) = dot( squeeze(m1_dirs(:, :, i)), m2_dirs, 2 );
end

end

function [dst_psth, dst_labels, t] = make_psth(events, event_labels, spikes, ei, si, varargin)

assert_ispair( events, event_labels );
assert( isempty(events) || iscolumn(events) );

defaults = struct();
defaults.min_t = [];
defaults.max_t = [];
defaults.bin_width = [];

params = shared_utils.general.parsestruct( defaults, varargin );
min_t = params.min_t;
max_t = params.max_t;
bin_width = params.bin_width;

[dst_psth, dst_labels, t] = gf_psth( ...
    spikes, si, events(ei), prune(event_labels(ei)), min_t, max_t, bin_width );

end

function [dst_psth, dst_labels, t] = psth_split_by_m2_quadrant(gf_outs, events, spikes, gi, ei, si, varargin)

defaults = struct();
defaults.accept_theta = [];
defaults.reject_theta = [];
defaults.min_t = [];
defaults.max_t = [];
defaults.bin_width = [];
defaults.iei_thresh = [];
defaults.align_to_eye_end = [];

params = shared_utils.general.parsestruct( defaults, varargin );
accept_theta = params.accept_theta;
reject_theta = params.reject_theta;
min_t = params.min_t;
max_t = params.max_t;
bin_width = params.bin_width;
iei_thresh = params.iei_thresh;
align_to_eye_end = params.align_to_eye_end;

m1_dirs = gf_outs.m1_dirs(gi, :);
m2_dirs = gf_outs.m2_dirs(gi, :);
evt_iei = gf_outs.m1_evt_iei(gi);
next_evti = gf_outs.next_m1_evt_ind(gi);
curr_eye_evti = gf_outs.targ_mask(gi);

quadrant_dirs = { [1, 0], [0, 1], [-1, 0], [0, -1] };
quadrant_dir_labels = { 'm2-right', 'm2-up', 'm2-left', 'm2-down' };

dst_psth = [];
dst_labels = fcat();
t = [];

evt_start = bfw.event_column( events, 'start_time' );
evt_end = bfw.event_column( events, 'stop_time' );

for qi = 1:numel(quadrant_dirs)
  qd = quadrant_dirs{qi};
  target_dirs = repmat( qd, rows(m2_dirs), 1 );
  m2_dot_t = dot( m2_dirs, target_dirs, 2 );
  m1_dot_t = dot( m1_dirs, target_dirs, 2 );
  valid_dirs = ~any( isnan(m1_dirs), 2 ) & ~any( isnan(m2_dirs), 2 );

  m2_within_cone = accept_within_cone( m2_dot_t, evt_iei, accept_theta, iei_thresh );
  m1_within_cone = accept_within_cone( m1_dot_t, evt_iei, accept_theta, iei_thresh );
  m1_outside_cone = reject_outside_cone( m1_dot_t, evt_iei, reject_theta, iei_thresh );

  m1_true_gf = m1_within_cone & m2_within_cone & valid_dirs;
  m1_null_gf = m2_within_cone & m1_outside_cone & valid_dirs;
  m1_control_gf = ~m2_within_cone & m1_within_cone & valid_dirs;

  assert( sum(m1_true_gf & m1_null_gf) == 0 && ...
          sum(m1_null_gf & m1_control_gf) == 0 && ...
          sum(m1_control_gf & m1_true_gf) == 0 );

  if ( align_to_eye_end )
    evt_inds = curr_eye_evti;
    evt_ts = evt_end;
  else
    evt_inds = next_evti;
    evt_ts = evt_start;
  end

  null_ei = ei(evt_inds(m1_null_gf));
  targ_ei = ei(evt_inds(m1_true_gf));
  ctrl_ei = ei(evt_inds(m1_control_gf));

  null_ts = evt_ts(null_ei);
  targ_ts = evt_ts(targ_ei);
  ctrl_ts = evt_ts(ctrl_ei);

  null_labels = make_null_event_labels( events.labels, null_ei );
  targ_labels = make_gf_event_labels( events.labels, targ_ei );
  ctrl_labels = make_control_event_labels( events.labels, ctrl_ei );

  [null_psth, null_psth_labels, t] = gf_psth( ...
    spikes, si, null_ts, null_labels, min_t, max_t, bin_width );
  [targ_psth, targ_psth_labels] = gf_psth( ...
    spikes, si, targ_ts, targ_labels, min_t, max_t, bin_width );
  [ctrl_psth, ctrl_psth_labels] = gf_psth( ...
    spikes, si, ctrl_ts, ctrl_labels, min_t, max_t, bin_width );

  tmp_labels = extend( null_psth_labels, targ_psth_labels, ctrl_psth_labels );
  tmp_psth = [ null_psth; targ_psth; ctrl_psth ];
  assert_ispair( tmp_psth, tmp_labels );

  if ( ~isempty(tmp_labels) )
    addsetcat( tmp_labels, 'm2-quadrant', quadrant_dir_labels{qi} );
    append( dst_labels, tmp_labels );
    dst_psth = [ dst_psth; tmp_psth ];
  else
    assert( isempty(tmp_psth) );
  end
end

end

function tf = accept_within_cone(cts, evt_iei, theta_thresh, iei_thresh) 
tf = cts >= cos(theta_thresh) & evt_iei <= iei_thresh;
end
function tf = reject_outside_cone(cts, evt_iei, theta_thresh, iei_thresh)
tf = cts < cos(theta_thresh) & evt_iei <= iei_thresh;
end