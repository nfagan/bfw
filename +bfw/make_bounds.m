function make_bounds(varargin)

import shared_utils.cell.percell;

conf = bfw.config.load();

defaults = struct();
defaults.files = [];
defaults.window_size = 500;
defaults.step_size = 1;
defaults.update_time = true;

params = bfw.parsestruct( defaults, varargin );

data_p = bfw.get_intermediate_directory( 'aligned' );

if ( isempty(params.files) )
  aligned_mats = shared_utils.io.find( data_p, '.mat' );
else
  aligned_mats = params.files;
end

unified_p = bfw.get_intermediate_directory( 'unified' );

data_root = conf.PATHS.data_root;

roi_p = bfw.get_intermediate_directory( 'rois' );
roi_mats = shared_utils.io.find( roi_p, '.mat' );
rects = percell( @shared_utils.io.fload, roi_mats );

save_p = bfw.get_intermediate_directory( 'bounds' );

copy_fields = { 'unified_filename', 'unified_directory' ...
  , 'aligned_filename', 'aligned_directory' };

window_size = params.window_size;
step_size = params.step_size;

for i = 1:numel(aligned_mats)
  fprintf( '\n %d of %d', i, numel(aligned_mats) );
  
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
  
  b_filename = bfw.make_intermediate_filename( m_dir, m_filename );
  
  for k = 1:numel(fields)
    bounds.(fields{k}).bounds = containers.Map();
    for j = 1:numel(rect_keys)
      key = rect_keys{j};
      x = aligned.(fields{k}).position(1, :);
      y = aligned.(fields{k}).position(2, :);
      t = aligned.(fields{k}).time;
      
      m_rect = rect.(fields{k}).rects(key);
      m_ib = bfw.bounds.rect( x, y, m_rect );
      
      %   add sliding window
      if ( params.update_time )
        [m_ib, t] = slide_window( m_ib, t, window_size, step_size );
      else
        m_ib = slide_window( m_ib, t, window_size, step_size );
      end
      %   end sliding window
      
      bounds.(fields{k}).bounds(key) = m_ib;
      bounds.(fields{k}).time = t;
    end
    for j = 1:numel(copy_fields)
      bounds.(fields{k}).(copy_fields{j}) = aligned.(fields{k}).(copy_fields{j});
    end
    bounds.(fields{k}).bounds_filename = b_filename;
    bounds.(fields{k}).bounds_directory = save_p;
  end
  
  bounds.window_size = window_size;
  bounds.step_size = step_size;

  shared_utils.io.require_dir( save_p );
  do_save( fullfile(save_p, b_filename), bounds );
end

end

function do_save( pathstr, variable )

save( pathstr, 'variable' );

end

function [out, out_t] = slide_window( bounds, t, window_size, step_size )

total = floor( numel(bounds) / step_size );

out = false( 1, total );
out_t = zeros( 1, total );

half_window = floor( window_size/2 );
start = half_window;
stop = min( total, start+window_size );
stp = window_size;

while ( stop <= total )
  out(stp) = any( bounds(start:stop-1) );
  out_t(stp) = t(start+half_window+1);
  if ( stop == total ), break; end
  stp = stp + 1;
  start = start + step_size;
  stop = start + window_size;
  stop = min( stop, total );
end

end
