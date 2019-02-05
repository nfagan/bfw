function bfw_check_match_aligned_indices(varargin)

defaults = bfw.get_common_make_defaults();

inputs = { 'plex_raw_time', 'aligned_raw_indices' };
output = '';

[params, loop_runner] = bfw.get_params_and_loop_runner( inputs, output, defaults, varargin );
loop_runner.convert_to_non_saving_with_output();

results = loop_runner.run( @check_match_aligned_indices );

end

function is_ok = check_match_aligned_indices(files)

is_ok = true;

time_file = shared_utils.general.get( files, 'plex_raw_time' );
align_file = shared_utils.general.get( files, 'aligned_raw_indices' );

sync_id = time_file.sync_id;

match_time = time_file.(sync_id);

other_field = char( setdiff({'m1', 'm2'}, sync_id) );

% if there's only one field (m1), no need to do the alignment.
if ( ~isfield(time_file, other_field) )
  return;
end

other_time = time_file.(other_field);

min_match = min( match_time );
max_match = max( match_time );

is_within_time_bounds = other_time >= min_match & other_time <= max_match;
inds_within_time_bounds = find( is_within_time_bounds );

tic;
other_indices = bfw.mex.m1_m2_align( match_time, other_time, inds_within_time_bounds );
toc;

if ( align_file.params.fill_gaps )
  other_indices = fill_gaps( other_indices, align_file.params.max_fill );
end

old_other_inds = align_file.(other_field);

were_equal = isequaln( old_other_inds(:), other_indices(:) );

if ( ~were_equal )
  non_eq = find( old_other_inds(:) ~= other_indices(:) );
  
  if ( numel(non_eq) ~= 2 || ~isnan(match_time(non_eq(2))) )
    fprintf( '\nIncorrect: %s', align_file.unified_filename );
  end
%   disp( match_time(non_eq) );
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