function [counts, count_labels] = bfw_aggregate_spatial_bins(spike_data, spatial_outs, varargin)

defaults = struct();
defaults.unit_mask_func = @(labels, mask) mask;
defaults.spatial_mask_func = @(labels, mask) mask;
defaults.psth_min_t = 0;
defaults.psth_max_t = 0.5;
defaults.psth_bin_width = 0.5;
defaults.measure = 'spikes';

params = bfw.parsestruct( defaults, varargin );

unit_each = { 'unit_uuid', 'region', 'session', 'unit_rating' };
spatial_each = { 'roi' };

unit_mask = params.unit_mask_func( spike_data.labels, rowmask(spike_data.labels) );
spatial_mask = params.spatial_mask_func( spatial_outs.labels, rowmask(spatial_outs.labels) );

[unit_labels, unit_I, unit_C] = keepeach( spike_data.labels', unit_each, unit_mask );
session_ind = ismember( unit_each, 'session' );

min_t = params.psth_min_t;
max_t = params.psth_max_t;
psth_bin_width = params.psth_bin_width;
measure = validatestring( params.measure, {'spikes', 'events', 'duration'} ...
  , mfilename, 'measure' );

all_counts = cell( numel(unit_I), 1 );
all_labels = cell( numel(unit_I), 1 );

events = spatial_outs.events;
spike_times = spike_data.spike_times;

for i = 1:numel(unit_I)
  fprintf( '\n  %d of %d', i, numel(unit_I) );
  
  spike_ts = vertcat( spike_times{unit_I{i}} );
  
  match_selectors = unit_C(session_ind, i);
  spatial_ind = find( spatial_outs.labels, match_selectors, spatial_mask );
  [tmp_labels, spatial_I] = keepeach( spatial_outs.labels', spatial_each, spatial_ind );
  
  tmp_counts = nan( joinsize(spatial_I, events) );
  
  for j = 1:numel(spatial_I)
    spatial_ind = spatial_I{j};
    
    squeezed = arrayfun( @(x) squeeze(events(x, :, :)), spatial_ind, 'un', 0 );
    combined = eachcell( @vertcat, squeezed{:} );
    starts = eachcell( @(x) if_nonempty(x, @() x(:, 1)), combined );
    
    if ( strcmp(measure, 'spikes') )
      psth_func = @(x) nanmean( bfw.trial_psth(spike_ts, x, min_t, max_t, psth_bin_width), 2 );
      counts = cellfun( @(x) if_nonempty(x, @() nanmean(psth_func(x)), @zeros), starts );
      
    elseif ( strcmp(measure, 'events') )
      counts = cellfun( @numel, starts );
      
    elseif ( strcmp(measure, 'duration') )
      stops = eachcell( @(x) if_nonempty(x, @() x(:, 2)), combined );
      counts = total_durations( starts, stops );
      
    else
      error( 'Unrecognized measure "%s".', measure );
    end
    
    tmp_counts(j, :, :) = counts;
  end
  
  all_counts{i} = tmp_counts;
  if ( ~isempty(tmp_labels) )
    all_labels{i} = join( tmp_labels, unit_labels(i) );
  end
end

counts = vertcat( all_counts{:} );
count_labels = vertcat( all_labels{:} );

end

function durs = total_durations(starts, stops)

durs = zeros( size(starts) );

for i = 1:numel(starts)
  starts_one_bin = starts{i};
  
  if ( ~isempty(starts_one_bin) )
    durs_one_bin = stops{i} - starts_one_bin;
    durs(i) = sum( durs_one_bin );
  end
end

end

function res = if_nonempty(x, t, varargin)

res = conditional( @() ~isempty(x), t, varargin{:} );

end