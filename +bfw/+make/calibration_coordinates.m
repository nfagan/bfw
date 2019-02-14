function coord_file = calibration_coordinates(files)

%   CALIBRATION_COORDINATES -- Create calibration coordinates file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%     FILES:
%       - 'edf'
%     OUT:
%       - `coord_file` (struct)

bfw.validatefiles( files, {'edf'} );

edf_file = shared_utils.general.get( files, 'edf' );
monkey_ids = intersect( fieldnames(edf_file), {'m1', 'm2'} );

coord_file = struct();
coord_file.unified_filename = bfw.try_get_unified_filename( edf_file );

for i = 1:numel(monkey_ids)
  monkey_id = monkey_ids{i};
  
  edf_obj = edf_file.(monkey_id).edf;
  
  assert( ~isempty(edf_obj) ...
    , 'Empty edf object; Edf2Mat class may not be on Matlab''s search path.' );
  
  coord_file.(monkey_id) = get_gaze_coordinates( edf_obj );
end

end

function coords = get_gaze_coordinates(edf_obj)

messages = edf_obj.Events.Messages;

info = messages.info;

is_gaze_coord_message = cellfun( @(x) ~isempty(strfind(lower(x), 'gaze_coords')) ...
  , info );

assert( nnz(is_gaze_coord_message) == 1, 'Expected 1 gaze coord message; found %d.' ...
  , nnz(is_gaze_coord_message) );

gaze_coord_message = info{is_gaze_coord_message};
str_coords = strsplit( gaze_coord_message, ' ' );

assert( numel(str_coords) == 5, 'Expected 5 elements in the gaze_coords array; found %d' ...
  , numel(str_coords) );

coords = str2double( str_coords(2:end) );

assert( ~any(isnan(coords)), 'Failed to parse gaze coordinates; NaN elements present.' );

end