function genders = monk_id_to_gender(monk_ids)

tmp_ids = cellstr( monk_ids );
genders = cell( size(tmp_ids) );

for i = 1:numel(tmp_ids)
  switch ( tmp_ids{i} )
    case 'hitch'
      genders{i} = 'male';
    case 'ephron'
      genders{i} = 'female';
    case 'cron'
      genders{i} = 'male';
    case 'lynch'
      genders{i} = 'male';
    otherwise
      error( 'Unhandled gender "%s".', tmp_ids{i} );
  end
end

if ( ischar(monk_ids) )
  genders = char( genders );
end

end