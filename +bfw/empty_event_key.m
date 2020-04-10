function evt_key = empty_event_key()

keys = { 'start_index', 'stop_index', 'length', 'start_time', 'stop_time', 'duration' };
evt_key = containers.Map();

for i = 1:numel(keys)
  evt_key(keys{i}) = [];
end

end