day_data = load( 'C:\Users\nick\Downloads\Lynch_full_data\Gaze_Data_Lynch.mat' );

%%

target_rois = { 'eyes', 'mouth' };
target_subjects = { 'm1', 'm2' };

look_back = 0;
look_ahead = 5e3;

% days = { 'data_01022020', 'data_07262019' };
days = fieldnames( day_data.GazeData );
[data, labels, t] = parse_days( day_data.GazeData, days, target_rois, target_subjects, look_back, look_ahead );

%%

function [data, labels, t] = parse_days(day_data, days, target_rois, target_subjects, look_back, look_ahead)

for i = 1:numel(days)
  fprintf( '\n %s (%d of %d)', days{i}, i, numel(days) );
  
  [dat, labs, t] = parse_day( ...
    day_data.(days{i}), days{i}, target_rois, target_subjects, look_back, look_ahead );
  if ( i == 1)
    data = dat;
    labels = labs;
  else
    data = cat_each( data, dat );
    labels = [ labels; labs ];    
  end
end

end

function [data, labels, t] = parse_day(day_data, day_name, target_rois, target_subjects, look_back, look_ahead)

run_names = fieldnames( day_data );

all_data = struct();
all_labels = {};

target_rois = cellstr( target_rois );
target_subjects = cellstr( target_subjects );
first = true;

for i = 1:numel(target_rois)
  for j = 1:numel(target_subjects)
    for k = 1:numel(run_names)
      run_name = run_names{k};

      names = struct();
      names.run = run_name;
      names.roi = target_rois{i};
      names.subject = target_subjects{j};
      names.day = day_name;

      [data, labels, t] = parse_run( ...
        day_data.(run_name), names, look_back, look_ahead );
      
      if ( first )
        all_data = data;
        first = false;
      else
        all_data = cat_each( all_data, data );
      end

      all_labels = [ all_labels; labels ];
    end
  end
end

data = all_data;
labels = all_labels;

end

function [data, labels, t] = parse_run(run, names, look_back, look_ahead)

stim_ts = run.stim_ts;
vec_size = look_ahead - look_back;
t = look_back:(look_back + vec_size - 1);

roi_name = names.roi;
run_name = names.run;
monk_name = names.subject;
day_name = names.day;

bounds_m = false( numel(stim_ts), vec_size );
dist_m = zeros( size(bounds_m) );
pupil_m = zeros( size(bounds_m) );

is_oob_stim = max( run.t ) - stim_ts < 5;

for i = 1:numel(stim_ts)
  if ( isnan(stim_ts(i)) )
    continue;
  end
  
  [~, t_ind] = min( abs(stim_ts(i) - run.t) );
  t_ind = t_ind - 1;
  
  target_begin = t_ind + look_back;
  target_end = t_ind + look_ahead;
  
  target_beg_off = 0;
  if ( target_begin < 0 )
    target_beg_off = abs( target_begin );
  end
  
  target_end_off = 0;
  if ( target_end > numel(run.t) )
    target_end_off = target_end - numel( run.t );
  end
  
  read_begin = target_begin + target_beg_off;
  read_end = target_end - target_end_off;

  read_v = (read_begin:(read_end-1)) + 1;
  dst_v = (target_beg_off:(vec_size - target_end_off - 1)) + 1;
  
  roi = run.(sprintf('roi_%s_%s', monk_name, roi_name));
  roi_cent = [ mean(roi([1, 3])), mean(roi([2, 4])) ];
  
  x = run.(sprintf('x_%s', monk_name))(read_v);
  y = run.(sprintf('y_%s', monk_name))(read_v);
  pupil = run.(sprintf('pupil_%s', monk_name))(read_v);  
  is_ib = x >= roi(1) & x < roi(3) & y >= roi(2) & y < roi(4);
  
  to_cent = [ x(:), y(:) ] - roi_cent(:)';
  dist = vecnorm( to_cent, 2, 2 );
  
  bounds_m(i, dst_v) = is_ib;
  dist_m(i, dst_v) = dist;
  pupil_m(i, dst_v) = pupil;
end

labels = cell( numel(stim_ts), 6 );
labels(:, 1) = run.all_stim_labels(:);
labels(:, 2) = repmat( {roi_name}, size(labels, 1), 1 );
labels(:, 3) = repmat( {run_name}, size(labels, 1), 1 );
labels(:, 4) = repmat( {day_name}, size(labels, 1), 1 );
labels(:, 5) = repmat( {monk_name}, size(labels, 1), 1 );
labels(:, 6) = arrayfun( @(x) x, is_oob_stim, 'un', 0 );

data = struct();
data.bounds = bounds_m;
data.pupil = pupil_m;
data.distance = dist_m;

end

function all_data = cat_each(all_data, data)

fs = fieldnames( data );
for i = 1:numel(fs)
  all_data.(fs{i}) = [ all_data.(fs{i}); data.(fs{i}) ];
end

end
