function ids = get_event_identifiers( events, name_space )

import shared_utils.char.string2hash;

ids = cell( size(events) );

stp = 1;

for i = 1:numel(events)
  subset_evts = events{i};
  ids{i} = zeros( size(subset_evts), 'uint64' );
  for j = 1:numel(subset_evts)
    id_str = sprintf( '%s__%d', name_space, stp );
    ids{i}(j) = uint64( string2hash(id_str) );
    stp = stp + 1;
  end
end

end