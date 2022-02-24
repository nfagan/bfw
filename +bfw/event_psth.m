function [psth_matrix, t] = event_psth(evt_start_ts, spike_times, evt_I, spk_I, min_t, max_t, bin_width)

%   EVENT_PSTH -- PSTH for event and spike subsets.
%
%     psth = bfw.event_psth( evts, spks, evt_I, spk_I, min_t, max_t, bin_width )
%     returns a cell array `psth` of spike count matrices computed
%     separately for each subset of `evts` indexed by `evt_I` and `spks`
%     indexed by `spk_I`.
%
%     `evt_I` and `spk_I` are cell arrays of the same size. The i-th
%     element of `evt_I` is an index into the array of `evts`. The i-th
%     element of `spk_I` is an index into the cell array of `spks`. For the
%     ith element of `evt_I`, a separate PSTH matrix aligned to the
%     corresponding set of `evts` is computed for each cell of 
%     `spks(spk_I{i})`. These matrices are concatenated in order and stored
%     in the ith element of `psth`.
%
%     `min_t` gives the amount of time to look back before each event, and 
%     `max_t` the amount of time to look ahead, with bins of size
%     `bin_width`.
%
%     [..., t] = bfw.event_matrix(...) also returns a cell array `t` of
%     time vectors identifying the columns of each element of `psth`.
%
%     See also bfw.trial_psth

assert( numel(evt_I) == numel(spk_I) );
psth_matrix = cell( size(evt_I) );
t = cell( size(psth_matrix) );

parfor i = 1:numel(evt_I)
  shared_utils.general.progress( i, numel(evt_I) );
  
  si = spk_I{i};
  ei = evt_I{i};
  
  spike_ts = spike_times(si);
  evt_ts = evt_start_ts(ei);
  
  sub_psth = [];
  bin_t = [];
  for j = 1:numel(spike_ts)
    spk_ts = spike_ts{j};
    [psth, bin_t] = bfw.trial_psth( ...
      spk_ts(:), evt_ts(:), min_t, max_t, bin_width );
    sub_psth = [ sub_psth; psth ];
  end
  
  psth_matrix{i} = sub_psth;
  t{i} = bin_t;
end

end