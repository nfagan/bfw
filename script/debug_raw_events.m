function debug_raw_events()

conf = bfw.config.load();

stim_files = bfw.require_intermediate_mats( [], bfw.gid('stim', conf), [] );

empties = false( numel(stim_files), 1 );

all_ib = cell( size(empties) );
all_ib_labs = cell( size(empties) );

parfor idx = 1:numel(stim_files)
  shared_utils.general.progress( idx, numel(stim_files), mfilename );
  
  stim_file = shared_utils.io.fload( stim_files{idx} );
  
  un_filename = stim_file.unified_filename;
  
  evt_file = bfw.load1( 'raw_events', un_filename, conf );
  
  if ( isempty(evt_file) )
    empties(idx) = true;
    continue; 
  end

  ssd = evt_file.params.samples_subdir;
  fsd = evt_file.params.fixations_subdir;

  bounds_file = bfw.load1( fullfile(ssd, 'bounds'), un_filename, conf );
  fix_file = bfw.load1( fullfile(ssd, fsd), un_filename, conf );
  t_file = bfw.load1( fullfile(ssd, 'time'), un_filename, conf );
  meta_file = bfw.load1( 'meta', un_filename, conf );
  
  if ( bfw.any_empty(bounds_file, fix_file, t_file, meta_file) )
    empties(idx) = true;
    continue;
  end

  event_times = evt_file.events(:, evt_file.event_key('start_time'));
  evt_labs = fcat.from( evt_file.labels, evt_file.categories );
  addsetcat( evt_labs, 'unified_filename', un_filename );
  
  d = 10;

  stim_times = stim_file.stimulation_times;
  sham_times = stim_file.sham_times;

  stim_events = [ stim_times(:); sham_times(:) ];
  stim_types = { 'stim', 'sham' };
  stim_indices = [ rowones(numel(stim_times)); repmat(2, numel(sham_times), 1) ];
  
  monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
  roi_names = keys( bounds_file.(char(monk_ids{1})) );
  
  C = combvec( 1:numel(monk_ids), 1:numel(roi_names) );
  n_combs = size( C, 2 );
  
  la = 5;
  lb = -1;
  sf = 1e3;

  t = t_file.t;
  t_series = lb:1/sf:la;

  in_bounds = false( numel(stim_events) * n_combs, numel(t_series) );
  ib_labs = fcat();
  
  stp = 1;
  
  for i = 1:numel(stim_events)
    evt = shared_utils.sync.nearest( t, stim_events(i) );

    start = evt + lb * sf;
    stop = evt + la * sf;
    
    assign_start = 1;
    assign_stop = size( in_bounds, 2 );

    if ( start < 1 )
      assign_start = abs( start ) + 2;
      
      start = 1;
    end
    if ( stop > numel(t) )
      overflow = stop - numel( t );
      assign_stop = assign_stop - overflow;
      
      stop = numel( t );
    end
    
    for j = 1:n_combs
      monk_id = monk_ids{C(1, j)};
      roi_name = roi_names{C(2, j)};

      bounds_container = bounds_file.(monk_id);
      fix_vec = fix_file.(monk_id);
      
      bounds = bounds_container(roi_name);

      is_fix = fix_vec(start:stop);
      ib = bounds(start:stop);
      
      is_valid = is_fix & ib;
      
      in_bounds(stp, assign_start:assign_stop) = is_valid;
      
      labs = fcat.create( ...
          'stim_type', stim_types{stim_indices(i)} ...
        , 'roi', roi_name ...
        , 'looks_by', monk_id ...
        , 'unified_filename', un_filename ...
        , 'session', meta_file.session ...
        , 'date', meta_file.date ...
      );
    
      append( ib_labs, labs );
      
      stp = stp + 1;
    end
  end
  
  all_ib{idx} = in_bounds;
  all_ib_labs{idx} = ib_labs;
end

all_ib(empties) = [];
all_ib_labs(empties) = [];

ib = vertcat( all_ib{:} );
ib_labs = vertcat( fcat(), all_ib_labs{:} );

outs = struct();
outs.ib_labels = ib_labs;
outs.ib = ib;

end

