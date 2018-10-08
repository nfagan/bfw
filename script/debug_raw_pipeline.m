evt1_file = bfw.load1( 'raw_events', '04242018' );

un_filename = evt1_file.unified_filename;

ssd = evt1_file.params.samples_subdir;
fsd = evt1_file.params.fixations_subdir;

evt2_file = bfw.load1( 'events', un_filename );
stim_file = bfw.load1( 'stim', un_filename );
bounds_file = bfw.load1( fullfile(ssd, 'bounds'), un_filename );
fix_file = bfw.load1( fullfile(ssd, fsd), un_filename );
t_file = bfw.load1( fullfile(ssd, 'time'), un_filename );

lab1 = fcat.from( evt1_file.labels, evt1_file.categories );

%%

eyes1_ind = find( lab1, {'m2', 'eyes'} );

eyes1 = evt1_file.events(eyes1_ind, evt1_file.event_key('start_time'));
eyes2 = evt2_file.times{evt2_file.monk_key('m2'), evt2_file.roi_key('eyes')};

plot( [eyes1(:)'; eyes1(:)'], repmat([0; 1], 1, numel(eyes1)), 'k--', 'linewidth', 1 );
hold on;
plot( [eyes2(:)'; eyes2(:)'], repmat([0; 1], 1, numel(eyes2)), 'r--' );

%%
stim_times = stim_file.stimulation_times(:);
sham_times = stim_file.sham_times(:);

all_times = [ stim_times; sham_times ];
stim_types = { 'stim', 'sham' };
indices = [ rowones(numel(stim_times)); repmat(2, numel(sham_times), 1) ];

event_times = evt1_file.events(:, evt1_file.event_key('start_time'));

t = t_file.t;

lb = -1;
la = 5;

bounds = [];
labs = fcat();
ts = [];

for i = 1:numel(event_times)
  target_start = event_times(i) + lb;
  target_stop = event_times(i) + la;
  
  if ( target_start < min(t) )
    continue;
  end
  
  [~, start] = min( abs(t - target_start) );
  [~, stop] = min( abs(t - target_stop) );
  
  roi_name = char( partcat(lab1, 'roi', i) );
  monk_id = char( partcat(lab1, 'looks_by', i) );
  
  if ( ~isfield(bounds_file, monk_id) )
    continue;
  end
  
  ib = bounds_file.(monk_id)(roi_name);
  is_fix = fix_file.(monk_id);
  
  is_valid = ib(start:stop) & is_fix(start:stop);
 
  append( labs, lab1, i );
  bounds = [ bounds; is_valid ];
  ts = [ ts; t(start:stop) - event_times(i) ];
end

use_t = ts(1, :);

mask = fcat.mask( labs, @find, {'m2', 'eyes'} );
[plabs, I] = keepeach( labs', {'roi', 'looks_by'}, mask );

ps = rowop( bounds, I, @(x) sum(x, 1) / rows(x) );

pl = plotlabeled.make_common();
pl.x = use_t;

pl.lines( ps, plabs', 'roi', 'looks_by' );