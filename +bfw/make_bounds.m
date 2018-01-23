function make_bounds()

import shared_utils.cell.percell;

conf = bfw.config.load();

data_p = bfw.get_intermediate_directory( 'aligned' );
aligned_mats = shared_utils.io.find( data_p, '.mat' );

unified_p = bfw.get_intermediate_directory( 'unified' );

data_root = conf.PATHS.data_root;

roi_p = bfw.get_intermediate_directory( 'rois' );
roi_mats = shared_utils.io.find( roi_p, '.mat' );
rects = percell( @shared_utils.io.fload, roi_mats );

save_p = bfw.get_intermediate_directory( 'bounds' );

base_filename = 'bounds';

copy_fields = { 'unified_filename', 'unified_directory' ...
  , 'aligned_filename', 'aligned_directory', 'time' };

do_save = true;

for i = 1:numel(aligned_mats)
  
  aligned = shared_utils.io.fload( aligned_mats{i} );
  roi_index = cellfun( @(x) strcmp(aligned.m1.unified_filename, x.m1.unified_filename), rects );
  
  assert( sum(roi_index) == 1, 'Only one roi can be associated with an alignment.' );
  
  rect = rects{roi_index};
  
  fields = fieldnames( aligned );
  
  rect_keys = rect.m1.rects.keys();
  
  bounds = struct();
  
  un_f = aligned.(fields{1}).unified_filename;
  
  meta = shared_utils.io.fload( fullfile(unified_p, un_f) );
  
  m_dir = meta.(fields{1}).mat_directory_name;
  m_filename = meta.(fields{1}).mat_filename;
  
  b_filename = bfw.make_intermediate_filename( base_filename, m_dir, m_filename );
  
  for k = 1:numel(fields)
    bounds.(fields{k}).bounds = containers.Map();
    for j = 1:numel(rect_keys)
      key = rect_keys{j};
      x = aligned.(fields{k}).position(1, :);
      y = aligned.(fields{k}).position(2, :);
      m_rect = rect.(fields{k}).rects(key);
      m_ib = bfw.bounds.rect( x, y, m_rect );
      bounds.(fields{k}).bounds(key) = m_ib;
    end
    for j = 1:numel(copy_fields)
      bounds.(fields{k}).(copy_fields{j}) = aligned.(fields{k}).(copy_fields{j});
    end
    bounds.(fields{k}).bounds_filename = b_filename;
    bounds.(fields{k}).bounds_directory = save_p;
  end  
  
  if ( do_save )
    shared_utils.io.require_dir( save_p );
    save( fullfile(save_p, b_filename), 'bounds' );
  end
end

end
