function offset_file = single_origin_offsets(files)

%   SINGLE_ORIGIN_OFFSETS -- Create single origin offsets file.
%
%     See also bfw.make.help
%
%     IN:
%       - `files` (containers.Map, struct)
%     FILES:
%       - 'calibration_coordinates'
%     OUT:
%       - `offset_file` (struct)

bfw.validatefiles( files, 'calibration_coordinates' );

calibration_file = shared_utils.general.get( files, 'calibration_coordinates' );

m_fields = intersect( fieldnames(calibration_file), {'m1', 'm2'} );

offset_file = struct();
offset_file.unified_filename = bfw.try_get_unified_filename( calibration_file );

use_screen_rect = [0, 0, 1024*3, 768];

% Adjust position so that, for each monk, origin is the top-left of
% *respective* screen, with coordinate (0, 0)
for i = 1:numel(m_fields)
  m_id = m_fields{i};
  
  screen_rect = calibration_file.(m_id);
  zero_offset = columnize( screen_rect(1:2) );
  
  offset_file.(m_id) = -zero_offset;
end

m2_to_m1 = zeros( 2, 1 );

if ( any(strcmp(m_fields, 'm2')) )
  m2_to_m1(1) = use_screen_rect(3);
end

offset_file.m2_to_m1 = m2_to_m1;

end