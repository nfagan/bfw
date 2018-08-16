

close all
% understand how to use container method

% all types of events
event_subset1 = all_event_times.only({'m1'});
event_dur_subset1 = all_event_lengths.only({'m1'});

figure,clf
plot_event(event_subset1.data, event_dur_subset1.data, 'm1'), hold on

event_subset2 = all_event_times.only({'m2'});
event_dur_subset2 = all_event_lengths.only({'m2'});

plot_event(event_subset2.data, event_dur_subset2.data, 'm2'), hold on

% spikes
% sorted_units = all_spike_times.require_fields('unit_id')
figure,clf
channels = all_spike_times.combs('channel');

for i = 1:numel(channels)
    spike_train = all_spike_times.only(channels{i});
    plot(spike_train.data{1}, i*ones(1,length(spike_train.data{1})),'.k'), hold on
end    
% xlim([2000 2030])