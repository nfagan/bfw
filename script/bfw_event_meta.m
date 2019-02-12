runner = bfw.get_looped_make_runner();
runner.convert_to_non_saving_with_output();

runner.input_directories = bfw.gid( {'raw_events', 'meta'} );

%%

results = runner.run( @(x) x );
outputs = { results([results.success]).output };

%%

events = cellfun( @(x) x('raw_events').events, outputs, 'un', 0 );
events = vertcat( events{:} );

labels = fcat();

for i = 1:numel(outputs)
  meta_file = outputs{i}('meta');
  event_file = outputs{i}('raw_events');
  
  meta_labs = bfw.struct2fcat( meta_file );
  event_labs = fcat.from( event_file.labels, event_file.categories );
  
  append( labels, join(event_labs, meta_labs) );
end

assert_ispair( events, labels );

%%

event_times = events(:, event_file.event_key('start_time'));

combs( labels, 'unified_filename', find(isnan(event_times)) )