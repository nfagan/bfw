function make_raw_aligned_indices(varargin)

ff = @fullfile;

import shared_utils.io.fload;

defaults = bfw.get_common_make_defaults();
defaults.fill_gaps = true;
defaults.max_fill = 3;

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

time_p = bfw.gid( ff('plex_raw_time', isd), conf );
aligned_p = bfw.gid( ff('aligned_raw_indices', osd), conf );

mats = bfw.require_intermediate_mats( params.files, time_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats), mfilename );
  
  time_file = fload( mats{i} );
  
  unified_filename = time_file.unified_filename;
  output_filename = fullfile( aligned_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  aligned_file = struct();
  aligned_file.params = params;
  aligned_file.unified_filename = unified_filename;
  
  sync_id = time_file.sync_id;
  
  match_time = time_file.(sync_id);
  match_indices = 1:numel(match_time);
  
  aligned_file.t = match_time;
  aligned_file.(sync_id) = match_indices;
  
  other_field = char( setdiff({'m1', 'm2'}, sync_id) );
  
  % if there's only one field (m1), no need to do the alignment.
  if ( ~isfield(time_file, other_field) )
    shared_utils.io.require_dir( aligned_p );
    shared_utils.io.psave( output_filename, aligned_file, 'aligned_file' );
    continue;
  end
  
  other_time = time_file.(other_field);

  min_match = min( match_time );
  max_match = max( match_time );

  other_indices = zeros( size(match_indices) );

  is_within_time_bounds = other_time >= min_match & other_time <= max_match;
  inds_within_time_bounds = find( is_within_time_bounds );
  n_use = numel( inds_within_time_bounds );

  for j = 1:n_use
    from_idx = inds_within_time_bounds(j);

    ct = other_time(from_idx);

    [~, to_idx] = min( abs(match_time - ct) );

    other_indices(to_idx) = from_idx;
  end
  
  if ( params.fill_gaps )
    other_indices = fill_gaps( other_indices, params.max_fill );
  end
  
  aligned_file.(other_field) = other_indices;
  
  shared_utils.io.require_dir( aligned_p );
  shared_utils.io.psave( output_filename, aligned_file, 'aligned_file' );
end

end

function other_inds = fill_gaps(other_indices, max_fill)

other_inds = other_indices;

sign_change = diff( other_indices ) < 0;
intermediate_zeros = find( sign_change ) + 1;

check_indices = [ (1:max_fill) * -1, 1:max_fill ];

for i = 1:numel(intermediate_zeros)
  ind = intermediate_zeros(i);
  
  for j = 1:numel(check_indices)
    full_ind = ind + check_indices(j);
    
    if ( full_ind > 0 && full_ind <= numel(other_indices) && other_indices(full_ind) ~= 0 )
      other_inds(ind) = other_indices(full_ind);
      break;
    end
  end
end

end