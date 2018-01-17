function new_dat = unify_raw_data(dat)

import shared_utils.assertions.*;

required_fields = { 'plex_sync_times', 'sync_times', 'reward_sync_times' };
all_fields = fieldnames( dat );
remaining_fields = setdiff( all_fields, union(required_fields, {'position', 'time', 'gaze'}) );

assert__are_fields( dat, required_fields );

new_dat = struct();

for i = 1:numel(dat)
  for j = 1:numel(required_fields)
    new_dat(i).(required_fields{j}) = dat(i).(required_fields{j});
  end
  for j = 1:numel(remaining_fields)
    new_dat(j).(remaining_fields{j}) = dat(i).(remaining_fields{j});
  end

  nan_ps = isnan( dat(i).plex_sync_times );
  new_dat(i).plex_sync_times = dat(i).plex_sync_times(~nan_ps);
  
  nan_st = any( isnan(dat(i).sync_times), 2 );
  new_dat(i).sync_times = dat(i).sync_times(~nan_st, :);

  nan_rs = isnan( dat(i).reward_sync_times );
  new_dat(i).reward_sync_times = dat(i).reward_sync_times(~nan_rs);

  if ( isfield(dat, 'position') )
    assert( size(dat(i).position, 1) == 3, 'Expected position to have 3 rows, but there were %d' ...
      , size(dat(i).position, 1) );
    assert( ~isfield(dat, 'time'), 'Expected data to not have a "time" field.' );

    nans = all( isnan(dat(i).position), 1 );
    
    dat(i).position(:, nans) = [];
    
    gx = dat(i).position(1, :);
    gy = dat(i).position(2, :);
    t = dat(i).position(3, :);
    
    new_dat(i).position = [gx; gy];
    new_dat(i).time = t;
    new_dat(i).pupil_size = nan( 1, size(dat(i).position, 2) );
  else
    assert( isfield(dat, 'gaze'), 'Expected data to have a "gaze" or "position" field.' );
    
    sz = size( dat(i).gaze, 1 );

    nans = all( isnan(dat(i).gaze), 1 );

    dat(i).gaze(:, nans) = [];

    if ( sz == 5 )
      gx = dat(i).gaze(1, :);
      gy = dat(i).gaze(2, :);
      pa = dat(i).gaze(3, :);
      t = dat(i).gaze(5, :);

      new_dat(i).position = [gx; gy];
      new_dat(i).time = t;
      new_dat(i).pupil_size = pa;
    else
      assert( sz == 4, 'Expected gaze data to have a size of 4 or 5, but it was %d', sz );

      gx = dat(i).gaze(1, :);
      gy = dat(i).gaze(2, :);
      pa = dat(i).gaze(3, :);
      t = dat(i).gaze(4, :);

      new_dat(i).position = [gx; gy];
      new_dat(i).time = t;
      new_dat(i).pupil_size = pa;
    end
  end
end

end