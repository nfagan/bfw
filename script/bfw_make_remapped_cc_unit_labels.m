spikes = bfw_gather_spikes( ...
    'spike_subdir', 'cc_spikes' ...
  , 'is_parallel', true ...
  , 'include_unit_index', true ...
);

%%

nday = unique( get_i_days('all') );
load('spike_data07312019') % sua

spktimes = {spike_data.times};
dates = {spike_data.date};
regions = {spike_data.region};
uuid = {spike_data.uuid};
channels = {spike_data.channel_str};
ratings = [spike_data.rating];
day_units = {};
rmap_idx = [];
rmap_uuid = {};
for iday = 1:numel(nday)
    idx = ismember(dates,nday{iday});
    units = spktimes(find(idx));
    day_units{iday} = units;
    day_region{iday} = regions(find(idx));
    rmap_idx = [rmap_idx find(idx)];
    rmap_uuid = [rmap_uuid uuid(find(idx))];
end
region_all = [];
region_all = cat(2,region_all,day_region{:});
rmap_channel = channels(rmap_idx);
rmap_ratings = arrayfun( @(x) sprintf('unit_rating__%d', x), ratings(rmap_idx), 'un', 0 );

%%

rmap_spike_data = spike_data(rmap_idx);
cc_unit_index_labels = cell( rows(spikes.labels), 1 );

for i = 1:numel(rmap_spike_data)
  spks = rmap_spike_data(i).times;
  matches = arrayfun( @(x) isequal(spks, x.times), spikes.units );
  assert( sum(matches) == 1 );
  
  index_label = sprintf( 'cc_unit_index__%d', i );
  addsetcat( spikes.labels, 'cc_unit_index', index_label, find(matches) );
  cc_unit_index_labels{matches} = index_label;
end

%%

x = bfw_ct.load_significant_social_cell_labels_from_anova( [], true );
for i = 1:size(x, 1)
  unit_info = x(i, {'unit_uuid', 'unit_index', 'region'} );
  match_ind = find( spikes.labels, unit_info );
  assert( numel(match_ind) == 1 );
end

%%

str_uuid = cellfun( @string, rmap_uuid );
str_region = string( region_all );
str_region(str_region == "accg") = "acc";
str_channels = string( rmap_channel );
str_ratings = string( rmap_ratings );

nf_format_labels = spikes.labels';
nf_uuids = nf_format_labels(:, {'unit_uuid', 'region', 'channel', 'unit_rating'});

visited_dup_394 = false;

for i = 1:size(nf_uuids, 1)
  uuid_num = strrep( nf_uuids{i, 1}, 'unit_uuid__', '' );
  match_ind = str_uuid == uuid_num & ...
              str_region == nf_uuids{i, 2} & ...
              str_channels == nf_uuids{i, 3} & ...
              str_ratings == nf_uuids{i, 4};
  
  try
    assert( sum(match_ind) == 1 );
  catch err
    assert( uuid_num == 394 );
    if ( ~visited_dup_394 )
      
    end
  end
end