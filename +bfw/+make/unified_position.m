function pos_file = unified_position(files)

bfw.validatefiles( files, {'unified', 'position'} );

unified_file = shared_utils.general.get( files, 'unified' );
pos_file = shared_utils.general.get( files, 'position' );

m_fields = intersect( fieldnames(unified_file), {'m1', 'm2'} );

if ( numel(m_fields) == 1 )
  % Only one monkey
  return
end

use_screen_rect = [ 0, 0, 1024*3, 768 ];

% Adjust position so that, for each monk, origin is the top-left of
% *respective* screen, with coordinate (0, 0)
for i = 1:numel(m_fields)
  m_id = m_fields{i};
  
  position = pos_file.(m_id);
  unified = unified_file.(m_id);
  
  screen_rect = bfw.field_or( unified, 'screen_rect', use_screen_rect );
  zero_offset = columnize(screen_rect(3:4)) - columnize(use_screen_rect(3:4));
  
  position(1, :) = position(1, :) - zero_offset(1);
  position(2, :) = position(2, :) - zero_offset(2);
  
  pos_file.(m_id) = position;  
end

% Now flip m2's x-position
pos_file.m2(1, :) = pos_file.m2(1, :) - use_screen_rect(3);

end