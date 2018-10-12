function make_reformatted_raw_events(varargin)

defaults = bfw.get_common_make_defaults();

params = bfw.parsestruct( defaults, varargin );

isd = params.input_subdir;
osd = params.output_subdir;

events_p = bfw.gid( fullfile('raw_events', isd) );
output_p = bfw.gid( fullfile('raw_events_reformatted', osd) );

mats = bfw.require_intermediate_mats( params.files, events_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  events_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = events_file.unified_filename;
  output_filename = fullfile( output_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    make_main( output_p, output_filename, unified_filename, events_file, params );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

function make_main(output_p, output_filename, unified_filename, events_file, params)

events = events_file.events;
event_key = events_file.event_key;

times = events(:, event_key('start_time'));
lengths = events(:, event_key('length'));
durations = events(:, event_key('duration'));

[~, roi_ind] = ismember( 'roi', events_file.categories );
[~, m_ind] = ismember( 'looks_by', events_file.categories );

rois = unique( events_file.labels(:, roi_ind) );
monks = unique( events_file.labels(:, m_ind) );

C = combvec( 1:numel(rois), 1:numel(monks) );

reformatted_times = cell( numel(rois), numel(monks) );
reformatted_lengths = cell( size(reformatted_times) );
reformatted_durations = cell( size(reformatted_times) );

roi_map = containers.Map();
monk_map = containers.Map();

for i = 1:size(C, 2)
  roi_i = C(1, i);
  monk_i = C(2, i);

  roi = rois{roi_i};
  monk = monks{monk_i};

  is_roi_label = strcmp( events_file.labels(:, roi_ind), roi );
  is_monk_label = strcmp( events_file.labels(:, m_ind), monk );

  is_selected = is_roi_label & is_monk_label;

  reformatted_times{roi_i, monk_i} = columnize(times(is_selected))';
  reformatted_lengths{roi_i, monk_i} = columnize(lengths(is_selected))';
  reformatted_durations{roi_i, monk_i} = columnize(durations(is_selected))';

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
reformatted_events_file.roi_key = roi_map;
reformatted_events_file.monk_key = monk_map;

shared_utils.io.require_dir( output_p );
shared_utils.io.psave( output_filename, reformatted_events_file, 'reformatted_events_file' );

end