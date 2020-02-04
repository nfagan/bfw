function [data, labels, mask] = day_level_average(data, labels, spec, mask)

use_spec = spec;
use_spec = setdiff( use_spec, {'unified_filename'} );
use_spec = union( use_spec, {'session'} );

[labels, each_I] = keepeach( labels', use_spec, mask );
data = bfw.row_nanmean( data, each_I );
mask = rowmask( labels );

end