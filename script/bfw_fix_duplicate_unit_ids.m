spikes = bfw_gather_spikes( ...
    'spike_subdir', 'cc_spikes' ...
  , 'include_unit_index', true ...
);

bfw.add_monk_labels( spikes.labels );

unit_cats = {'unit_uuid', 'region', 'channel', 'session'};
original_unit_info = cellstr( spikes.labels, unit_cats );
unit_uuids = original_unit_info(:, 1);

%%  find duplicates and relabel

dups = false( size(unit_uuids) );
remapped = false( size(unit_uuids) );
remap = containers.Map();

id_offset = 1e4;

replaced_unit_uuids = unit_uuids;

for i = 1:numel(unit_uuids)
  match_ind = strcmp( unit_uuids, unit_uuids{i} );
  if ( sum(match_ind) > 1 )
    dups(i) = true;
    if ( ~remap.isKey(unit_uuids{i}) )
      unit_id = fcat.parse( unit_uuids{i}, 'unit_uuid__' );
      assert( ~isnan(unit_id) );
      new_id = unit_id + id_offset;
      new_id_str = sprintf( 'unit_uuid__%d', new_id );
      remap(unit_uuids{i}) = 1;
      replaced_unit_uuids{i} = new_id_str;
      remapped(i) = true;
    end
  elseif ( strcmp(unit_uuids{i}, 'unit_uuid__598b') )
    replaced_unit_uuids{i} = sprintf( 'unit_uuid__%d', 598+id_offset );
    remapped(i) = true;
  end
end

assert( numel(unique(replaced_unit_uuids)) == numel(replaced_unit_uuids) );

%%  find corresponding cc unit index labels

outs = get_cc_unit_id_info();
rmap_spike_data = outs.spike_data(outs.rmap_idx);
cc_unit_index_labels = cell( rows(spikes.labels), 1 );

for i = 1:numel(rmap_spike_data)
  spks = rmap_spike_data(i).times;
  matches = arrayfun( @(x) isequal(spks, x.times), spikes.units );
  assert( sum(matches) == 1 );
  
  index_label = sprintf( 'cc_unit_index__%d', i );
  addsetcat( spikes.labels, 'cc_unit_index', index_label, find(matches) );
  cc_unit_index_labels{matches} = index_label;
end

%%  load anatomy

xls_p = 'D:\data\bfw\public\coordinates';
xls_file = shared_utils.io.find( xls_p, '.xlsx' );
assert( numel(xls_file) == 1 );
[~, ~, raw] = xlsread( xls_file{1} );
xls_out = bfw_parse_anatomy_excel_file( raw );

match_categories = { 'unit_uuid', 'channel', 'unit_rating' };
[~, match_ind] = ismember( match_categories, xls_out.categories );

src_unit_info = cellstr( spikes.labels, match_categories );
match_unit_info = xls_out.labels(:, match_ind);

match_str = fcat.strjoin( match_unit_info' )';
search_src = fcat.strjoin( src_unit_info' )';

missing_src = false( numel(search_src), 1 );
dup_src = false( size(missing_src) );
coords = nan( numel(search_src), 3 );

for i = 1:size(search_src, 1)
  match_ind = strcmp( match_str, search_src{i} );
  if ( nnz(match_ind) == 0 )
    assert( false );
    missing_src(i) = true;
  else
    if ( nnz(match_ind) > 1 )
      src_coords = xls_out.coords(match_ind, :);
      assert( size(unique(src_coords, 'rows'), 1) == 1 );
    end
    coords(i, :) = xls_out.coords(find(match_ind, 1), :);
  end
end

info_cats = {'unit_uuid', 'channel', 'region', 'session', 'id_m1'};
all_src_info = cellstr( spikes.labels, info_cats );

missing_unit_ids = all_src_info(missing_src, :);
missing_unit_ids(:, 1) = strrep( missing_unit_ids(:, 1), 'unit_uuid__', '' );

do_save = false;
if ( do_save )
  file_p = fullfile( bfw.dataroot, 'public' );
  dsp3.req_writetable( array2table(missing_unit_ids, 'VariableNames', info_cats) ...
    , fullfile(file_p, 'unit_ids') ...
    , fcat.create('status', 'missing_ids_from_anatomy_xls'), 'status' );
end

%%  recombine as single id matrix

original_info = original_unit_info;
new_info = [ original_info, replaced_unit_uuids, cc_unit_index_labels ];

new_info(:, 1) = strrep( new_info(:, 1), 'unit_uuid__', '' );
new_info(:, 5) = strrep( new_info(:, 5), 'unit_uuid__', '' );
new_info(:, end) = strrep( new_info(:, end), 'cc_unit_index__', '' );
new_info(:, end+1) = strrep( cellstr(spikes.labels, 'unit_index'), 'unit_index__', '' );
new_info(:, end+1) = strrep( cellstr(spikes.labels, 'id_m1'), 'm1_', '' );
new_info(:, end+1) = arrayfun( @(x) char(string(x)), remapped, 'un', 0 );
new_info = [ new_info, arrayfun(@identity, coords, 'un', 0) ];

new_header = { 'original_uuid', 'region', 'channel', 'session', 'new_uuid', 'cc_uuid', 'unit_index', 'm1', 'is_relabeled' };
new_header = [ new_header, xls_out.coord_categories ];

id_tbl = array2table( new_info, 'VariableNames', new_header );

do_save = true;
if ( do_save )
  file_p = fullfile( bfw.dataroot, 'public' );
  dsp3.req_writetable( id_tbl ...
    , fullfile(file_p, 'unit_ids') ...
    , fcat.create('status', 'id_matrix'), 'status' );
  
  to_save = struct();
  to_save.info = new_info;
  to_save.header = new_header;
  save( fullfile(file_p, 'unit_ids', 'id_matrix.mat'), 'to_save' );
end

%%  store pre / post replaced ids explicitly

pre_replacement = original_unit_info(remapped, :);
post_replacement = [ replaced_unit_uuids(remapped), original_unit_info(remapped, 2:end) ];

pre_replace_tbl = array2table( pre_replacement, 'VariableNames', unit_cats );
post_replace_tbl = array2table( post_replacement, 'VariableNames', unit_cats );

do_save = true;
if ( do_save )
  file_p = fullfile( bfw.dataroot, 'public' );
  
  dsp3.req_writetable( pre_replace_tbl ...
    , fullfile(file_p, 'unit_ids') ...
    , fcat.create('status', 'pre_replacement'), 'status' );
  
  dsp3.req_writetable( post_replace_tbl ...
    , fullfile(file_p, 'unit_ids') ...
    , fcat.create('status', 'post_replacement'), 'status' );
end

%%

function outs = get_cc_unit_id_info()

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

outs = struct();
outs.str_uuid = cellfun( @string, rmap_uuid );
outs.str_region = string( region_all );
outs.str_region(outs.str_region == "accg") = "acc";
outs.str_channels = string( rmap_channel );
outs.str_ratings = string( rmap_ratings );
outs.cc_uuid = 1:numel(rmap_uuid);
outs.rmap_idx = rmap_idx;
outs.spike_data = spike_data;

end