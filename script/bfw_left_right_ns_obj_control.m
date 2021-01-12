conf = bfw.config.load();

sorted_events = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/events/sorted_events.mat') );

%%

ns_obj_mask_func = ...
  @(l, m) setdiff(m, bfw.find_sessions_before_nonsocial_object_was_added(l));

%%

spike_data = bfw_gather_spikes( ...
  'config', conf ...
  , 'spike_subdir', 'cc_spikes' ...
  , 'is_parallel', true ...
);

bfw.add_monk_labels( spike_data.labels );

%%

unit_mask = ns_obj_mask_func( spike_data.labels, rowmask(spike_data.labels) );
event_mask = ns_obj_mask_func( sorted_events.labels, rowmask(sorted_events.labels) );

unit_I = findall( spike_data.labels, {'unit_uuid', 'region', 'session'}, unit_mask );

start_ts = bfw.event_column( sorted_events, 'start_time' );

perm_params = struct( ...
  'iters', 1e2 ...
  , 'psth_min_t', 0 ...
  , 'psth_max_t', 0.5 ...
  , 'psth_bin_size', 0.05 ...
);

ps = [];
p_labels = fcat();

for i = 1:numel(unit_I)
  shared_utils.general.progress( i, numel(unit_I) );
  
  session = combs( spike_data.labels, 'session', unit_I{i} );
  
  obj_ind_l = find( sorted_events.labels, [session, {'left_nonsocial_object'}], event_mask );
  obj_ind_r = find( sorted_events.labels, [session, {'right_nonsocial_object'}], event_mask );
  
  [tmp_ps, tmp_p_labels] = ...
    permutation_test( start_ts, sorted_events.labels, obj_ind_l, obj_ind_r, spike_data, unit_I{i}, params );
  
  ps = [ps; tmp_ps];
  append( p_labels, tmp_p_labels );
end

%%

save_p = fullfile( bfw.dataroot(conf), 'analyses', 'left_right_obj_control' );
shared_utils.io.require_dir( save_p );
save_file = fullfile( save_p, 'permutation_test.mat' );
save( save_file, 'ps', 'p_labels' );

%%

do_save = true;

pl = plotlabeled.make_common();
pl.pie_include_percentages = true;

plt_labels = p_labels';
addsetcat( plt_labels, 'sig', 'sig_false' );
setcat( plt_labels, 'sig', 'sig_true', find(ps < 0.05) );
[props, prop_labels] = proportions_of( plt_labels, {'region'}, 'sig' );

axs = pl.pie( props*1e2, prop_labels, 'sig', 'region' );

if ( do_save )
  save_p = fullfile( bfw.dataroot(conf), 'plots', 'left_right_obj_control', dsp3.datedir );
  shared_utils.plot.fullscreen( gcf );
  dsp3.req_savefig( gcf, save_p, prop_labels, 'region' );
end

%%

function [ps, p_labels] = ...
  permutation_test(event_starts, event_labels, obj_ind_l, obj_ind_r, spike_data, spike_mask, params)

perm_iters = params.iters;
min_t = params.psth_min_t;
max_t = params.psth_max_t;
bin_size = params.psth_bin_size;

units = spike_data.spike_times(spike_mask);

ps = nan( numel(units), 1 );
p_labels = fcat();

for i = 1:numel(units)
  ts = units{i};
  
  real_diffs = zeros( perm_iters, 1 );
  null_diffs = zeros( perm_iters, 1 );

  for j = 1:perm_iters
    [shuff_l, shuff_r] = shuffle2( obj_ind_l, obj_ind_r );
    [shuff_l, shuff_r] = resample_to_smallest( shuff_l, shuff_r );
    [real_l, real_r] = resample_to_smallest( obj_ind_l, obj_ind_r );
    
    null_l = event_starts(shuff_l);
    null_r = event_starts(shuff_r);
    real_l = event_starts(real_l);
    real_r = event_starts(real_r);
    
    null_l = bfw.trial_psth( ts, null_l, min_t, max_t, bin_size );
    null_r = bfw.trial_psth( ts, null_r, min_t, max_t, bin_size );
    real_l = bfw.trial_psth( ts, real_l, min_t, max_t, bin_size );
    real_r = bfw.trial_psth( ts, real_r, min_t, max_t, bin_size );
    
    null_l = nanmean( nanmean(null_l, 2) );
    null_r = nanmean( nanmean(null_r, 2) );
    real_l = nanmean( nanmean(real_l, 2) );
    real_r = nanmean( nanmean(real_r, 2) );

    real_diffs(j) = real_r - real_l;
    null_diffs(j) = null_r - null_l;
  end
  
  ps(i) = signrank( real_diffs, null_diffs );
  append1( p_labels, spike_data.labels, spike_mask(i) );
end

end

function [a, b] = shuffle2(a, b)

num_a = numel( a );
tmp = [ a; b ];
tmp = tmp(randperm(numel(tmp)));

a = tmp(1:num_a);
b = tmp((num_a+1):end);

end

function [a, b] = resample_to_smallest(a, b)

num_keep = min( numel(a), numel(b) );

a = a(randperm(numel(a), num_keep));
b = b(randperm(numel(b), num_keep));

end