function aligned_file = raw_aligned_lfp(files, varargin)

defaults = bfw.make.defaults.raw_aligned_lfp();
params = bfw.parsestruct( defaults, varargin );

events_subdir = params.events_subdir;

bfw.validatefiles( files, {events_subdir, 'lfp'} );

lfp_file = shared_utils.general.get( files, 'lfp' );
events_file = shared_utils.general.get( files, events_subdir );

events_file = handle_roi_selection( events_file, params.rois );

unified_filename = bfw.try_get_unified_filename( events_file );

events = events_file.events;
event_key = events_file.event_key;

n_events = rows( events );
n_channels = rows( lfp_file.data );

event_inds = 1:n_events;
chan_inds = 1:n_channels;

c = combvec( chan_inds, event_inds );
n_combs = size( c, 2 );
lfp_indices = c(1, :);
event_indices = c(2, :);

event_times = events(:, event_key('start_time'));
t = lfp_file.id_times;
lfp_key = lfp_file.key;
% id_time_inds = arrayfun( @(x) shared_utils.sync.nearest(t, x), event_times );
id_time_inds = bfw.find_nearest( t, event_times );

look_ahead = params.look_ahead;
look_back = params.look_back;
window_size = params.window_size;

total_n_samples = look_ahead - look_back + window_size;
all_lfp_data = nan( n_events * n_channels, total_n_samples );

lfp_keys = keys( lfp_file.key_column_map );
[~, I] = sort( cellfun(@(x) lfp_file.key_column_map(x), lfp_keys) );

event_labs = fcat.from( events_file.labels, events_file.categories );

lfp_cats = lfp_keys(I);
lfp_labs = fcat.from( lfp_key, lfp_cats );

join( event_labs, lfp_labs(1) );
% all_labs = fcat.like( event_labs );

[mat_event_labs, mat_event_cats] = categorical( event_labs );

for i = 1:n_combs
  chani = c(1, i);
  evti = c(2, i);
  
  id_ind = id_time_inds(evti);
  
  start = floor( id_ind + look_back - (window_size/2) );
  stop = floor( id_ind + look_ahead + window_size - (window_size/2) );
  
  if ( start > 0 && stop <= numel(t) + 1 )
    all_lfp_data(i, :) = lfp_file.data(chani, start:stop-1);
  end
  
%   append( all_labs, event_labs, evti );
%   setcat( all_labs, lfp_cats, lfp_file.key(chani, :), i );
end

is_lfp_cat = ismember( mat_event_cats, lfp_cats );
reformatted_labs = mat_event_labs(event_indices, :);
reformatted_labs(:, is_lfp_cat) = lfp_file.key(lfp_indices, :);

all_labs = fcat.from( reformatted_labs, mat_event_cats );

aligned_file = struct();
aligned_file.params = params;
aligned_file.unified_filename = unified_filename;
aligned_file.data = all_lfp_data;
aligned_file.labels = categorical( all_labs );
aligned_file.categories = getcats( all_labs );
aligned_file.lfp_indices = lfp_indices;
aligned_file.event_indices = event_indices;

end

function events_file = handle_roi_selection(events_file, rois)

rois = cellstr( rois );

if ( numel(rois) == 1 && strcmp(rois, 'all') )
  return
end

roi_ind = strcmp( events_file.categories, 'roi' );
assert( nnz(roi_ind) == 1, 'Found %d ''roi'' categories; expected 1.', nnz(roi_ind) );

matches_roi = cellfun( @(x) any(strcmp(rois, x)), events_file.labels(:, roi_ind) );

events_file.labels(~matches_roi, :) = [];
events_file.events(~matches_roi, :) = [];

end