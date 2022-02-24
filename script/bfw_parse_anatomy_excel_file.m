function out = bfw_parse_anatomy_excel_file(raw)

cols = { 'ml', 'ap', 'z', 'id', 'unit', 'channel', 'rating', 'day', 'rating' };
inds = shared_utils.xls.find_in_header( cols, raw(1, :) ...
  , 'exact_match', false ...
  , 'error_on_not_found', true ...
);

content = raw(2:end, :);
ids = cell( rows(content), 1 );
indices = cell( size(ids) );
channels = cell( size(ids) );
sessions = cell( size(ids) );
ratings = cell( size(ids) );
coords = zeros( rows(content), 3 );
non_nan = true( rows(content), 1 );

for i = 1:rows(content)
  cs = content(i, inds(1:3));
  cs = [ cs{:} ];
  assert( numel(cs) == 3 );
  coords(i, :) = cs;
  
  id = content{i, inds(4)};
  if ( ischar(id) )
    ids{i} = sprintf( 'unit_uuid__%s', id );
  else
    ids{i} = sprintf( 'unit_uuid__%s', num2str(id) );
    if ( isnan(id) )
      non_nan(i) = false;
    end
  end
  
  rating = content{i, inds(7)};
  if ( rating == 0 )
    non_nan(i) = false;
  end
  
  index = content{i, inds(5)};
  assert( isnumeric(index) );
  indices{i} = sprintf( 'unit_index__%d', index );
  
  chan = content{i, inds(6)};
  assert( isnumeric(chan) );
  if ( chan < 10 )
    channels{i} = sprintf( 'SPK0%d', chan );
  else
    channels{i} = sprintf( 'SPK%d', chan );
  end
  
  session = num2str( content{i, inds(8)} );
  sessions{i} = session;
  
  ratings{i} = sprintf( 'unit_rating__%s', num2str(content{i, inds(9)}) );
end

out = struct();
out.coords = coords;
out.labels = [ids, indices, channels, sessions, ratings];
out.categories = { 'unit_uuid', 'unit_index', 'channel', 'session', 'unit_rating' };
out.coord_categories = { 'ml', 'ap', 'z' };
out.non_nan = non_nan;

end

function target_labels = add_sessions_from_unit_ids(spike_labels, target_labels)

[unit_I, unit_C] = findall( target_labels, {'unit_uuid', 'region'} );
addcat( target_labels, 'session' );

for i = 1:numel(unit_I)
  sessions_this_unit = combs( spike_labels, 'session', find(spike_labels, unit_C(:, i)) );
  try
    assert( numel(sessions_this_unit) == 1 );
  catch err
    if ( isequal(sessions_this_unit, {'08302018', '08312018'}) )
      warning( 'More than 1 session matched' );
    elseif ( isequal(sessions_this_unit, {'08272018', '08282018'}) )
      warning( 'More than 1 session matched' );
    else
      throw( err );
    end
  end
  setcat( target_labels, 'session', sessions_this_unit{1}, unit_I{i} );
end

end