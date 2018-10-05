function make_bounds(varargin)

ff = @fullfile;

import shared_utils.cell.percell;

defaults = bfw.get_common_make_defaults();

defaults.window_size = 500;
defaults.step_size = 1;
defaults.update_time = true;
defaults.remove_blink_nans = true;
defaults.require_fixation = true;
defaults.single_roi_fixations = false;
defaults.fixations_subdir = '';

params = bfw.parsestruct( defaults, varargin );
conf = params.config;

isd = params.input_subdir;
osd = params.output_subdir;
fsd = params.fixations_subdir;

data_p = bfw.gid( ff('aligned', isd), conf );
blink_p = bfw.gid( ff('blinks', isd), conf );
fix_p = bfw.gid( ff('fixations', fsd), conf );
unified_p = bfw.gid( ff('unified', isd), conf );
roi_p = bfw.gid( ff('rois', isd), conf );
save_p = bfw.gid( ff('bounds', osd), conf );

aligned_mats = bfw.require_intermediate_mats( params.files, data_p, params.files_containing );

copy_fields = { 'unified_filename', 'aligned_filename', 'aligned_directory' };

window_size = params.window_size;
step_size = params.step_size;

parfor i = 1:numel(aligned_mats)
  fprintf( '\n %d of %d', i, numel(aligned_mats) );
  
  aligned = shared_utils.io.fload( aligned_mats{i} );
  
  fields = intersect( {'m1', 'm2'}, fieldnames(aligned) );
  first = fields{1};
  
  un_f = aligned.(fields{1}).unified_filename;
  
  roi_filename = fullfile( roi_p, un_f );
  
  if ( ~shared_utils.io.fexists(roi_filename) )
    warning( 'Missing roi file for "%s".', un_f );
    continue;
  end
  
  rect = shared_utils.io.fload( roi_filename );
  rect_keys = rect.(first).rects.keys();
  
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
  
  %   first get bounds  
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
  
  %   separate eyes from face
  for k = 1:numel(fields)
    c_bounds = bounds.(fields{k}).bounds;
    
    c_bounds('face') = c_bounds('face') & ~c_bounds('eyes');
    c_bounds('face') = c_bounds('face') & ~c_bounds('mouth');
    
    bounds.(fields{k}).bounds = c_bounds;
  end  
  
  %   then apply fixations
  if ( params.require_fixation )
    for k = 1:numel(fields)
      c_fix = fix_file.(fields{k});
      c_bounds = bounds.(fields{k}).bounds;

      t = bounds.(fields{k}).time;

      %   if true, for each fixation:
      %     count the number of samples that are in bounds for each roi.
      %     assign the fixation to the roi with the maximum number of
      %     samples.
      %   otherwise, use the same is_fixation vector for each roi.
      if ( params.single_roi_fixations )
        fix_id = cell( 1, numel(c_fix.start_indices) );

        for j = 1:numel(c_fix.start_indices)
          start_index = c_fix.start_indices(j);
          stop_index = c_fix.stop_indices(j);

          ns = zeros( size(rect_keys) );

          for h = 1:numel(rect_keys)
            roi = rect_keys{h};
            c_bounds_vec = c_bounds(roi);        
            ns(h) = sum( c_bounds_vec(start_index:stop_index) );
          end

          %   right now, we assign a fixation to an roi based on the maximum
          %   number of samples that fall into that roi.
          [~, max_index] = max( ns );

          fix_id{j} = rect_keys{max_index};
        end

        per_roi_fix = containers.Map();

        for j = 1:numel(rect_keys)
          roi = rect_keys{j};

          adjusted_fix_vec = false( size(c_fix.is_fixation) );

          matching_fix = find( strcmp(fix_id, roi) );

          for h = 1:numel(matching_fix)
            fix_index = matching_fix(h);
            start_index = c_fix.start_indices(fix_index);
            stop_index = c_fix.stop_indices(fix_index);
            stop_index = min( stop_index, numel(adjusted_fix_vec) );
            adjusted_fix_vec(start_index:stop_index) = true;
          end

          per_roi_fix(roi) = adjusted_fix_vec;  
        end
      else
        per_roi_fix = containers.Map();
        for j = 1:numel(rect_keys)
          roi = rect_keys{j};
          per_roi_fix(roi) = c_fix.is_fixation;
        end
      end
    end
  end
  
  for k = 1:numel(fields)
    c_bounds = bounds.(fields{k}).bounds;
    for j = 1:numel(rect_keys)
      roi = rect_keys{j};
      
      m_ib = c_bounds(roi);
      
      %   & operation to include fixations, only
      if ( params.require_fixation )
        m_ib = m_ib & per_roi_fix(roi);
      end
      
      [m_ib, adjusted_t] = slide_window( m_ib, t, window_size, step_size );
      %   end sliding window
      
      bounds.(fields{k}).bounds(roi) = m_ib;
      bounds.(fields{k}).time = adjusted_t;
    end
  end
  
  bounds.window_size = window_size;
  bounds.step_size = step_size;
  bounds.adjustments = containers.Map(); 

  shared_utils.io.require_dir( save_p );
  do_save( full_filename, bounds );
end

end

function do_save( pathstr, bound )

save( pathstr, 'bound' );

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
