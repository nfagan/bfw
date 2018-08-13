function ids = get_duplicate_uuids( cont )

import shared_utils.assertions.*;

assert__isa( cont, 'Container' );

[I, C] = cont.get_indices( {'unit_uuid', 'channel'} );

unique_ids = cont('unit_uuid');

is_duplicate = cellfun( @(x) sum(strcmp(C(:, 1), x)) > 1, unique_ids );

ids = unique_ids(is_duplicate);

end