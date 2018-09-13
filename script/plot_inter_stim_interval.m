function plot_inter_stim_interval()

unified_p = bfw.gid( 'unified' );
stim_p = bfw.gid( 'stim' );

stim_files = shared_utils.io.find( stim_p, '.mat' );

all_isis = [];
all_labs = fcat();

for i = 1:numel(stim_files)
  shared_utils.general.progress( i, numel(stim_files) );
  
  stim_file = shared_utils.io.fload( stim_files{i} );
  un_file = shared_utils.io.fload( fullfile(unified_p, stim_file.unified_filename) );
  
  monk_dirs = fieldnames( un_file );
  first_field = monk_dirs{1};
  
  task_type = bfw.field_or( un_file.(first_field), 'task_type', 'free_viewing' );
  
  stim_isis = diff( stim_file.stimulation_times );
  sham_isis = diff( stim_file.sham_times );
  
  labs = fcat.create( ...
      'unified_filename', stim_file.unified_filename ...
    , 'session', un_file.m1.mat_directory_name ...
    , 'stim_type', 'stim' ...
    , 'task_type', task_type ...
  );

  n_stim = numel( stim_isis );
  n_sham = numel( sham_isis );
  
  all_isis = [ all_isis; stim_isis(:); sham_isis(:) ];
  
  append( all_labs, repmat(labs', n_stim) );
  append( all_labs, setcat(repmat(labs', n_sham), 'stim_type', 'sham') );
end

%%  plot

f = figure(1);
clf( f );

pltdat = all_isis;
pltlabs = all_labs';

pcats = { 'stim_type', 'task_type' };
[I, C] = findall( pltlabs, pcats );
shp = plotlabeled.get_subplot_shape( numel(I) );
axs = gobjects( size(I) );

meds = nan( size(I) );
ns = nan( size(I) );

for i = 1:numel(I)
  ax = subplot( shp(1), shp(2), i );
  
  some_dat = pltdat(I{i});
  hist( ax, some_dat, 100 );
  hold( ax, 'on' );
  
  title( ax, strrep(strjoin(C(:, i), ' | '), '_', ' ') );
  
  meds(i) = median( some_dat );
  ns(i) = numel( some_dat );
  axs(i) = ax;
end

shared_utils.plot.match_xlims( axs );
shared_utils.plot.match_ylims( axs );

ys = get( axs(1), 'ylim' );

arrayfun( @(x, y) plot(x, [y;y], ys, 'k--', 'linewidth', 2), axs, meds );
arrayfun( @(x, y, z) text(x, y(1)+2, ys(2)-1, sprintf('M=%0.2f, N=%d', y, z)) ...
  , axs, meds, ns );

end