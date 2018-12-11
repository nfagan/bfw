function reformatted_events_file = reformatted_events(files, varargin)

%   REFORMATTED_EVENTS -- Create reformatted events file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%       - `varargin` ('name', value)
%     FILES:
%       - 'raw_events'
%     OUT:
%       - `reformatted_events_file` (struct)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );

events_file = shared_utils.general.get( files, 'raw_events' );
unified_filename = bfw.try_get_unified_filename( events_file );

events = events_file.events;
event_key = events_file.event_key;
categories = events_file.categories;

times = events(:, event_key('start_time'));
lengths = events(:, event_key('length'));

[~, roi_ind] = ismember( 'roi', events_file.categories );
[~, m_ind] = ismember( 'looks_by', events_file.categories );

rois = unique( events_file.labels(:, roi_ind) );
monks = unique( events_file.labels(:, m_ind) );

C = combvec( 1:numel(rois), 1:numel(monks) );

reformatted_times = cell( numel(rois), numel(monks) );
reformatted_lengths = cell( size(reformatted_times) );
reformatted_durations = cell( size(reformatted_times) );
reformatted_initiated = cell( size(reformatted_times) );

step_size = events_file.params.step_size;

roi_map = containers.Map();
monk_map = containers.Map();
init_map = get_initiated_map();

for i = 1:size(C, 2)
  roi_i = C(1, i);
  monk_i = C(2, i);

  roi = rois{roi_i};
  monk = monks{monk_i};

  is_roi_label = strcmp( events_file.labels(:, roi_ind), roi );
  is_monk_label = strcmp( events_file.labels(:, m_ind), monk );

  is_selected = is_roi_label & is_monk_label;
  
  select_labels = events_file.labels(is_selected, :);

  reformatted_times{roi_i, monk_i} = columnize(times(is_selected))';
  reformatted_lengths{roi_i, monk_i} = columnize(lengths(is_selected))';
  %   in old format, durations was integer ms.
  reformatted_durations{roi_i, monk_i} = columnize(lengths(is_selected))' * step_size;
  reformatted_initiated{roi_i, monk_i} = get_initiated( monk, init_map, select_labels, categories );

  if ( ~isKey(monk_map, monk) )
    monk_map(monk) = monk_i;
  end

  if ( ~isKey(roi_map, roi) )
    roi_map(roi) = roi_i;
  end
end

reformatted_events_file = struct();
reformatted_events_file.unified_filename = unified_filename;
reformatted_events_file.params = params;
reformatted_events_file.times = reformatted_times;
reformatted_events_file.lengths = reformatted_lengths;
reformatted_events_file.durations = reformatted_durations;
reformatted_events_file.initiated = reformatted_initiated;
reformatted_events_file.roi_key = roi_map;
reformatted_events_file.monk_key = monk_map;
reformatted_events_file.initiated_key = init_map;

end

function m = get_initiated_map()

m = containers.Map();
m('m1') = 1;
m('m2') = 2;
m('simultaneous') = 0;

end

function ids = get_initiated(monk, key, labels, categories)

is_mut = strcmp( monk, 'mutual' );

if ( ~is_mut )
  ids = repmat( key(monk), 1, rows(labels) );
  return
end

init_col_ind = find( strcmp(categories, 'initiator') );
assert( numel(init_col_ind) == 1, 'Missing "initiator" column.' );

initiator = labels(:, init_col_ind);
initiator_id = cellfun( @(x) x(1:2), initiator, 'un', 0 );

ids = zeros( 1, rows(labels) );

for i = 1:numel(initiator_id)
  init_id = initiator_id{i};
  
  if ( isKey(key, init_id) )
    ids(i) = key(init_id); 
  end
end

end