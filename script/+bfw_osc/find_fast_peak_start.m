function i = find_fast_peak_start(bin_centers, slow_filt, deg_thresh, acorr_W)

i = 0;
bin0_ind = bin_centers == 0;

assert( nnz(bin0_ind) == 1, '0 or more than 1 zero bin found.' );

slope_thresh = tan( deg2rad(deg_thresh) );
scale_factor = acorr_W / slow_filt(bin0_ind);
min_bin = min( bin_centers );

while ( i > min_bin )
  ind = find( bin_centers == i );
  
  slope = slow_filt(ind) - slow_filt(ind-1);
  slope = abs( slope * scale_factor );
  
  if ( i < 0 && slope < slope_thresh )
    break;
  end
  
%   fprintf( '\n Thresh: %0.3f; Slope: %0.3f', slope_thresh, slope );
  
  i = i - 1;
end

if ( i <= min_bin )
  error( 'No fast peak detected.' );
end

end