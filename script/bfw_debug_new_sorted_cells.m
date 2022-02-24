spktimes = {spike_data.times};
dates = {spike_data.date};
regions = {spike_data.region};
uuid = {spike_data.uuid};
uuid_nums = arrayfun( @identity, 1:numel(uuid), 'un', 0 );

%%

pg_data = load( 'C:\Users\nick\Downloads\sorted_neural_data_social_gaze.mat' );

%%

f_regions = categorical( [dates(:), regions(:)] );
[dates_regs, ~, ic] = unique( f_regions, 'rows' );
reg_I = groupi( ic );

src_data = [];

for i = 1:numel(reg_I)  
  date = char( dates_regs(i, 1) );
  reg = char( dates_regs(i, 2) );
  
  ri = reg_I{i};
    
  spk_inds = cellfun( @(x) ceil(x * 40e3), spktimes(ri), 'un', 0 );
  spk_channel = cellfun( @(x) ones(size(x)), spk_inds, 'un', 0 );
  spk_unit_num = arrayfun( @(x, y) repmat(y, size(x{1})), spk_inds(:)', 1:numel(ri), 'un', 0 );
  % 1: channel
  % 2: spike time
  % 3: unit number
  spk_inds = horzcat( spk_inds{:} );
  spk_channel = horzcat( spk_channel{:} );
  spk_unit_num = horzcat( spk_unit_num{:} );
  
  s = struct();
  s.filename = date;
  s.region = reg;
  s.n_units = numel( ri );
  s.uuid = cat( 2, uuid_nums{ri} );
  s.spikeindices = [spk_channel; spk_inds; spk_unit_num];
  s.maxchn = ones( size(s.uuid) );
  s.validity = ones( size(s.uuid) );
  
  if ( i == 1 )
    src_data = s;
  else
    src_data(end+1) = s;
  end
end

%%

solo_evts = load( 'C:\data\bfw\public\interactive_events\interactive_solo_event_times' );
solo_evts = solo_evts.(char(fieldnames(solo_evts)));
join_evts = load( 'C:\data\bfw\public\interactive_events\interactive_event_times' );
join_evts = join_evts.(char(fieldnames(join_evts)));

evt_labels = [ addsetcat(solo_evts.event_labels', 'roi', 'eyes'); join_evts.labels ];
evt_times = [ solo_evts.events(:, 1); join_evts.events ];

src_data = load( 'C:\Users\nick\Downloads\cc_data.mat' );
src_data = src_data.(char(fieldnames(src_data)));
[spike_times, spike_labels, spike_categories] = linearize_spike_times( src_data, 40e3 );
spk_labels = fcat.from( spike_labels, spike_categories );

%%

[evt_I, evt_C] = findall( evt_labels, 'session' );
spk_I = bfw.find_combinations( spk_labels, evt_C );

[psth, t] = bfw.event_psth( evt_times, spike_times, evt_I, spk_I, -1.05, 1.05, 0.01 );
psth_labels = bfw.event_psth_labels( evt_labels, spk_labels, evt_I, spk_I );

psth = vertcat( psth{:} );
psth_labels = vertcat( fcat, psth_labels{:} );
assert_ispair( psth, psth_labels );

%%

smooth_psth = convn( psth, rectwin(10)', 'valid' );

%%

test_each = { 'uuid', 'initiator', 'follower' };
[test_labs, test_I] = keepeach( psth_labels', test_each );

is_sig = false( numel(test_I), 1 );
test_psth = smooth_psth;

i_solo = find_for_each( psth_labels, test_I, 'solo-event' );
i_join = find_for_each( psth_labels, test_I, 'joint-event' );

ps = ranksum_matrix( smooth_psth, i_solo, i_join );

%%

is_sig = false( size(ps, 1), 1 );
for i = 1:size(ps, 1)
  [~, dur] = shared_utils.logical.find_islands( ps(i, :) < 0.05 );
  is_sig(i) = any( dur >= 5 );
end

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