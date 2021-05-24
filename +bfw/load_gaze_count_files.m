function out = load_gaze_count_files(files)

out = [];

for i = 1:numel(files)
  shared_utils.general.progress( i, numel(files) );
  f = shared_utils.io.fload( files{i} );
  
  if ( i == 1 )
    out = f;
  else
    out.spikes = [ out.spikes; f.spikes ];
    out.labels = [ out.labels'; f.labels ];
    out.events = [ out.events; f.events ];
    out.event_labels = [ out.event_labels'; f.event_labels ];
  end
end

end