function make_bounds(varargin)

import shared_utils.cell.percell;

defaults = bfw.get_common_make_defaults();

defaults.window_size = 500;
defaults.step_size = 1;
defaults.update_time = true;
defaults.remove_blink_nans = true;
defaults.require_fixation = true;

params = bfw.parsestruct( defaults, varargin );

data_p = bfw.get_intermediate_directory( 'aligned' );
blink_p = bfw.get_intermediate_directory( 'blinks' );
fix_p = bfw.get_intermediate_directory( 'fixations' );

aligned_mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

unified_p = bfw.get_intermediate_directory( 'unified' );

roi_p = bfw.get_intermediate_directory( 'rois' );
roi_mats = shared_utils.io.find( roi_p, '.mat' );
rects = percell( @shared_utils.io.fload, roi_mats );

save_p = bfw.get_intermediate_directory( 'bounds' );

copy_fields = { 'unified_filename', 'aligned_filename', 'aligned_directory' };

window_size = params.window_size;
step_size = params.step_size;

parfor i = 1:numel(aligned_mats)
  fprintf( '\n %d of %d', i, numel(aligned_mats) );
  
  aligned = shared_utils.io.fload( aligned_mats{i} );
  
  fields = { 'm1', 'm2' };
  
  un_f = aligned.(fields{1}).unified_filename;
  
  roi_index = cellfun( @(x) strcmp(aligned.m1.unified_filename, x.m1.unified_filename), rects );
  
  assert( sum(roi_index) == 1, 'Expected 1 roi to be associated with "%s"; instead there were %d' ...
    , un_f, sum(roi_index) );
  
  rect = rects{roi_index};
  
  rect_keys = rect.m1.rects.keys();
  
  bounds = struct();
  
  meta = shared_utils.io.fload( fullfile(unified_p, un_f) );
  
  if ( params.require_fixation )
    fix_file = shared_utils.io.fload( fullfile(fix_p, un_f) );
  end
  
  if ( params.remove_blink_nans )
    blinks = shared_utils.io.fload( fullfile(blink_p, un_f) );
  end
  
  m_dir = meta.(fields{1}).mat_directory_name;
  m_filename = meta.(fields{1}).mat_filename;
  
  b_filename = bfw.make_intermediate_filename( m_dir, m_filename );
  
  full_filename = fullfile( save_p, b_filename );
  
  if ( bfw.conditional_skip_file(full_filename, params.overwrite) ), continue; end
  
  for k = 1:numel(fields)
    bounds.(fields{k}).bounds = containers.Map();
    for j = 1:numel(rect_keys)
      key = rect_keys{j};
      
      x = aligned.(fields{k}).position(1, :);
      y = aligned.(fields{k}).position(2, :);
      t = aligned.(fields{k}).time;
      
      m_rect = rect.(fields{k}).rects(key);
      
      m_blink_thresh = NaN;
      
      if ( params.remove_blink_nans )
        m_blink_thresh = round( median(blinks.(fields{k}).durations) );
      end
      
      %   if there are no blinks ... (unlikely)
      if ( isnan(m_blink_thresh) ), m_blink_thresh = Inf; end
      
      if ( params.remove_blink_nans )
        [m_ib, n_included_blink_x, n_included_blink_y, n_included_samples] = ...
          bfw.bounds.rect_excluding_blinks( x, y, m_rect, m_blink_thresh );
        n_included_blinks = max( n_included_blink_x, n_included_blink_y );
      else
        m_ib = bfw.bounds.rect( x, y, m_rect );
        n_included_blinks = NaN;
        n_included_blink_x = NaN;
        n_included_blink_y = NaN;
        n_included_samples = NaN;
      end
      
      %   & operation to include fixations, only
      if ( params.require_fixation )
        m_ib = m_ib & fix_file.(fields{k}).is_fixation;
      end
      
      %   add sliding window
      if ( params.update_time )
        [m_ib, t] = slide_window( m_ib, t, window_size, step_size );
      else
        m_ib = slide_window( m_ib, t, window_size, step_size );
      end
      %   end sliding window
      
      bounds.(fields{k}).bounds(key) = m_ib;
      bounds.(fields{k}).time = t;
      bounds.(fields{k}).n_included_blinks = n_included_blinks;
      bounds.(fields{k}).n_included_blink_x = n_included_blink_x;
      bounds.(fields{k}).n_included_blink_y = n_included_blink_y;
      bounds.(fields{k}).n_included_samples = n_included_samples;
    end
    for j = 1:numel(copy_fields)
      bounds.(fields{k}).(copy_fields{j}) = aligned.(fields{k}).(copy_fields{j});
    end
    bounds.(fields{k}).bounds_filename = b_filename;
    bounds.(fields{k}).bounds_directory = save_p;
  end
  
  bounds.window_size = window_size;
  bounds.step_size = step_size;
  bounds.adjustments = containers.Map(); 

  shared_utils.io.require_dir( save_p );
  do_save( full_filename, bounds );
end

end

function do_save( pathstr, variable )

save( pathstr, 'variable' );

end

function [out, out_t] = slide_window( bounds, t, window_size, step_size )

total = floor( numel(bounds) / step_size );

N = numel( bounds );

out = false( 1, total );
out_t = zeros( 1, total );

half_window = floor( window_size/2 );
start = 1;
stp = 1;
stop = min( N, start+window_size );

while ( stop <= N )
  out(stp) = any( bounds(start:stop-1) );
  out_t(stp) = t(start+half_window);
  stp = stp + 1;
  start = start + step_size;
  stop = start + window_size;
end

end
