function is_fix = eye_mmv_is_fixation(x, y, time, params)

pos = [ x(:)'; y(:)' ];

t1 = params.t1;
t2 = params.t2;
min_duration = params.min_duration;

%   repositories/eyelink/eye_mmv
is_fix = is_fixation( pos, time(:)', t1, t2, min_duration );
is_fix = logical( is_fix );
is_fix = is_fix(1:numel(time))';

end