function mask = find_non_error_runs(labels, mask)

if ( nargin < 2 )
  mask = rowmask( labels );
end

make_unfilename = @(day, num) sprintf('%s_image_control_%d.mat', day, num);
make_unfilenames = @(day, nums) arrayfun( @(x) make_unfilename(day, x), nums, 'un', 0 );

mask = fcat.mask( labels, mask ...
  , @findnone, make_unfilename('04202019', 1) ...
  , @findnone, make_unfilenames('04222019', [1, 2]) ...
  , @findnone, make_unfilenames('04282019', [1:3, 8]) ...
  , @findnone, make_unfilename('05052019', 1) ...
);

end