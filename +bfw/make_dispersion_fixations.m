function make_dispersion_fixations(varargin)

defaults = bfw.get_common_make_defaults();
defaults.min_duration = 0.01;
defaults.n_samples = 4;
defaults.interval = 50;
defaults.threshold = 20;

params = bfw.parsestruct( defaults, varargin );

aligned_p = bfw.get_intermediate_directory( 'aligned' );
unified_p = bfw.get_intermediate_directory( 'unified' );
output_p = bfw.get_intermediate_directory( 'fixations' );

aligned_mats = bfw.require_intermediate_mats( params.files, aligned_p, params.files_containing );

threshold = params.threshold;
interval = params.interval;
n_samples = params.n_samples;

for i = 1:numel(aligned_mats)
  fprintf( '\n %d of %d', i, numel(aligned_mats) );
  
  aligned_file = shared_utils.io.fload( aligned_mats{i} );
  
  un_filename = aligned_file.m1.unified_filename;
  
  unified_file = shared_utils.io.fload( fullfile(unified_p, un_filename) );
  
  output_filename = fullfile( output_p, un_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  monks = { 'm1', 'm2' };
  
  fix_struct = struct();
  fix_struct.unified_filename = un_filename;
  fix_struct.params = params;
  
  for j = 1:numel(monks)    
    monk = monks{j};
    
    pos = aligned_file.(monk).position;
    time = aligned_file.(monk).time;
    
    is_fix = is_dispersion_fixation( pos, n_samples, interval, threshold );
    is_fix = is_fix(:)';
    [starts, lengths] = shared_utils.logical.find_all_starts( is_fix );
    
    stops = starts + lengths - 1;
    
    fix_struct.(monk).time = time;
    fix_struct.(monk).is_fixation = is_fix;
    fix_struct.(monk).start_indices = starts;
    fix_struct.(monk).stop_indices = stops;
  end
  
  shared_utils.io.require_dir( output_p );
  
  do_save( output_filename, fix_struct );
end

end

function tf = is_dispersion_fixation(pos, n_samples, interval, threshold)

N = size( pos, 2 );
coords = nan( 2, n_samples );
tf = false( 1, N );

stp = 0;

for i = 1:interval:N
  if ( stp < n_samples )
    stp = stp + 1;
  else
    for j = 1:stp-1
      coords(:, j) = coords(:, j+1);
    end
  end
  
  coords(:, stp) = pos(:, i);
  
  maxs = nan( 2, 1 );
  
  first_iter = true;
  
  for j = 1:stp-1
    for k = j+1:stp
      
      a = coords(:, j);
      b = coords(:, k);
      
      dx = abs( a(1) - b(1) );
      dy = abs( a(2) - b(2) );
      
      if ( first_iter || dx > maxs(1) )
        maxs(1) = dx;
      end
      if ( first_iter || dy > maxs(2) )
        maxs(2) = dy;
      end
      
      first_iter = false;
    end
  end
  
  dispersion = mean( maxs );
  
  stop_pt = min( i + interval - 1, N );  
  tf(i:stop_pt) = dispersion < threshold;
end

end

function do_save( filepath, fix_struct )

save( filepath, 'fix_struct' );

end