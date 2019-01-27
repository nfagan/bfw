function offset_file = single_origin_offsets(files)

unified_file = shared_utils.general.get( files, 'unified' );

m_fields = intersect( fieldnames(unified_file), {'m1', 'm2'} );

offset_file = struct();
offset_file.unified_filename = bfw.try_get_unified_filename( unified_file );

use_screen_rect = [ 0, 0, 1024*3, 768 ];

% Adjust position so that, for each monk, origin is the top-left of
% *respective* screen, with coordinate (0, 0)
for i = 1:numel(m_fields)
  m_id = m_fields{i};
  
  unified = unified_file.(m_id);
  
  screen_rect = bfw.field_or( unified, 'screen_rect', use_screen_rect );
  zero_offset = columnize(screen_rect(3:4)) - columnize(use_screen_rect(3:4));
  
  offset_file.(m_id) = -zero_offset;
end

if ( any(strcmp(m_fields, 'm2')) )
  offset_file.m2(1) = offset_file.m2(1) - use_screen_rect(3);
end

end