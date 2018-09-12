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
  
  stim_isis = diff( stim_file.stimulation_times );
  sham_isis = diff( stim_file.sham_times );
  
  labs = fcat.create( ...
      'unified_filename', stim_file.unified_filename ...
    , 'session', un_file.m1.mat_directory_name ...
    , 'stim_type', 'stim' ...
  );

  n_stim = numel( stim_isis );
  n_sham = numel( sham_isis );
  
  all_isis = [ all_isis; stim_isis(:); sham_isis(:) ];
  
  append( all_labs, repmat(labs', n_stim) );
  append( all_labs, setcat(repmat(labs', n_sham), 'stim_type', 'sham') );
end

%%  plot

pl = plotlabeled();

pltdat = all_isis;
pltlabs = all_labs';

pcats = { 'stim_type' };

pl.hist( pltdat, pltlabs, pcats, 100 );



end