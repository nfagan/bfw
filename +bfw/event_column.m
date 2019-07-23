function events = event_column(event_file, kind, mask)

events = event_file.events(:, event_file.event_key(kind));

if ( nargin > 2 )
  events = events(mask);
end

end