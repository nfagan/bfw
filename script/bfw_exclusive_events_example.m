evt_file = bfw.load1( 'raw_events', [], bfw_st.default_config );

start_indices = bfw.event_column( evt_file, 'start_index' );
stop_indices = bfw.event_column( evt_file, 'stop_index' );

labels = fcat.from( evt_file );

mask = { rowmask(labels) };
keep = bfw_exclusive_events( start_indices, stop_indices, labels, {{'eyes_nf', 'everywhere'}}, mask );

mask = { keep };
keep = bfw_exclusive_events( start_indices, stop_indices, labels, {{'eyes_nf', 'face'}}, mask );

mask = { keep };
keep = bfw_exclusive_events( start_indices, stop_indices, labels, {{'face', 'everywhere'}}, mask );