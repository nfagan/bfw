function [raster, bin_starts] = trial_raster(spikes, events, min_t, max_t, bin_width, bin_step)

if ( nargin < 6 )
  bin_step = bin_width;
end

bin_starts = min_t:bin_step:max_t;
bin_ends = bin_starts + bin_width;
raster = false( numel(events), numel(bin_starts) );

parfor i = 1:numel(events)
  event_rel = spikes - events(i);
  for j = 1:numel(event_rel)
    event_spk = event_rel(j);
    bin_ind = event_spk >= bin_starts & event_spk < bin_ends;
    raster(i, :) = raster(i, :) | bin_ind;
  end
end

end