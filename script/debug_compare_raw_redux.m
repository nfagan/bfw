x = bfw.load1( 'raw_events_reformatted' );
y = bfw.load1( 'events', x.unified_filename );

%%

conf = bfw.config.load();

meta_p = bfw.gid( 'meta', conf );
orig_events_p = bfw.gid( 'events', conf );

mats = shared_utils.io.find( bfw.gid('raw_events_reformatted', conf), '.mat' );

all_times = [];
all_labs = fcat();

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  reform_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = reform_file.unified_filename;
  
  try
    orig_file = shared_utils.io.fload( fullfile(orig_events_p, unified_filename) );
    meta_file = shared_utils.io.fload( fullfile(meta_p, unified_filename) );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
  
  t1 = orig_file.times{1};
  t2 = reform_file.times{1};
  
  tmp_labs = fcat.from( struct2cell(meta_file)', fieldnames(meta_file) );
  
  try
    prune( bfw.get_region_labels(tmp_labs) );
  end
  
  repmat( tmp_labs, numel(t1) + numel(t2) );
  addcat( tmp_labs, 'event_type' );
  setcat( tmp_labs, 'event_type', 'original', 1:numel(t1) );
  setcat( tmp_labs, 'event_type', 'reformatted', numel(t1)+1:rows(tmp_labs) );  
  
  all_times = [ all_times; t1(:); t2(:) ];
  
  append( all_labs, tmp_labs );    
end

prune( all_labs );

%%

