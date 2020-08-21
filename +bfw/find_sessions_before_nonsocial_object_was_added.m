function ind = find_sessions_before_nonsocial_object_was_added(labels, mask)

if ( nargin < 2 )
  mask = rowmask( labels );
end

last_session_without_obj = '02092018';
[session_I, sessions] = findall( labels, 'session', mask );

date_format = 'mmddyyyy';
date_nums = datenum( sessions, date_format );
last_session_without_obj_num = ...
  datenum( last_session_without_obj, date_format );

preceding_obj = date_nums <= last_session_without_obj_num;
ind = sort( vertcat(session_I{preceding_obj}) );

end