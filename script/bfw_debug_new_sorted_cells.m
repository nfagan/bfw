%%  load

solo_evts = shared_utils.io.fload( 'C:\data\bfw\public\interactive_events\interactive_solo_event_times.mat' );
join_evts = shared_utils.io.fload( 'C:\data\bfw\public\interactive_events\interactive_event_times.mat' );
src_data = shared_utils.io.fload( 'C:\Users\nick\Downloads\cc_data.mat' );

%%  reformat

evt_labels = [ addsetcat(solo_evts.event_labels', 'roi', 'eyes'); join_evts.labels ];
evt_times = [ solo_evts.events(:, 1); join_evts.events ];
rmcat( evt_labels, {'region', 'cc-unit-index', 'cc-uuid'} );

[spike_times, spike_labels, spike_categories] = linearize_spike_times( src_data, 40e3 );
spk_labels = fcat.from( spike_labels, spike_categories );

%%  compute psth

[evt_I, evt_C] = findall( evt_labels, 'session' );
spk_I = bfw.find_combinations( spk_labels, evt_C );

bin_width = 0.01;
min_t = -1.0;
max_t = 1.0;
[psth, t] = bfw.event_psth( evt_times, spike_times, evt_I, spk_I, min_t, max_t, bin_width );
psth_labels = bfw.event_psth_labels( evt_labels, spk_labels, evt_I, spk_I );

psth = vertcat( psth{:} );
psth_labels = vertcat( fcat, psth_labels{:} );
assert_ispair( psth, psth_labels );

smooth_psth = convn( psth, rectwin(10)', 'valid' );
smooth_t = -1:bin_width:1;

%%  ranksum test

test_each = { 'uuid', 'initiator', 'follower' };
[test_labs, test_I] = keepeach( psth_labels', test_each );

i_solo = find_for_each( psth_labels, test_I, 'solo-event' );
i_join = find_for_each( psth_labels, test_I, 'joint-event' );

ps = ranksum_matrix( smooth_psth, i_solo, i_join );

is_sig = false( size(ps, 1), 1 );
t_mask = smooth_t >= 0 & smooth_t < 0.5;
% t_mask = true( 1, size(psth, 2) );

for i = 1:size(ps, 1)
  [~, dur] = shared_utils.logical.find_islands( ps(i, t_mask) < 0.05 );
  is_sig(i) = any( dur >= 5 );
end

%%  prop sig

[prop_labs, prop_I] = keepeach( test_labs', {'region', 'initiator', 'follower'} );
props = cellfun( @(x) pnz(is_sig(x)), prop_I );
cts = cellfun( @(x) sum(is_sig(x)), prop_I );

pl = plotlabeled.make_common();
axs = pl.bar( props, prop_labs, {'initiator', 'follower'}, 'region', 'roi' );

%%

function [spike_times, spike_labels, spike_categories] = linearize_spike_times(src_data, sr)

spike_times = {};
spike_labels = categorical( [] );

for i = 1:numel(src_data)
  sd = src_data(i);
  fname = sd.filename;
  reg = sd.region;
  n_units = sd.n_units;
  for j = 1:n_units
    is_unit = sd.spikeindices(3, :) == j;
    unit_ts = sd.spikeindices(2, is_unit) / sr;
    
    unit_labs = categorical( {fname, reg, sprintf('uuid-%d', sd.uuid(j))} );
    spike_times{end+1, 1} = unit_ts;
    spike_labels(end+1, :) = unit_labs;
  end
end

spike_categories = { 'session', 'region', 'uuid' };

end