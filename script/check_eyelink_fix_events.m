un_file = '02042018_position_1.mat';
aligned = bfw.load_one_intermediate( 'aligned', un_file );

fixations = bfw.load_one_intermediate( 'fixations', un_file );

edf = bfw.load_one_intermediate( 'edf', un_file );

%%

edf_files = bfw.require_intermediate_mats( [], bfw.get_intermediate_directory('edf'), [] );
bad_edfs = false( size(edf_files) );

for i = 1:numel(edf_files)
  edf = shared_utils.io.fload( edf_files{i} );
  fs = { 'm1', 'm2' };
  for j = 1:numel(fs)
    if ( isempty(edf.(fs{j}).edf) || ~isfield(edf.(fs{j}).edf.Events, 'Efix') )
      bad_edfs(i) = true;
      break;
    end
  end
end

% edf = bfw.load_one_intermediate( 'edf', '01312018_position_1');

%%

m2_aligned = aligned.m2;
m2_fix = fixations.m2.original;

%%

figure(1); clf();

t = m2_aligned.time;
pos = m2_aligned.position;
is_fix = m2_fix.is_fixation;

start_t = 100;
win_size = 5;

t_ind = t >= start_t & t < start_t + win_size;

plot( t(t_ind), pos(1, t_ind), 'r', 'linewidth', 1 );

hold on;

plot( t(t_ind & is_fix), mean(get(gca, 'ylim')), 'ko', 'markersize', 0.5 );

%%

un_file = '02042018_position_1.mat';

edf = bfw.load_one_intermediate( 'edf', un_file );

m2_edf = edf.m2.edf;

pos = [m2_edf.Samples.posX(:)'; m2_edf.Samples.posY(:)'];
t = m2_edf.Samples.time(:)';

starts = m2_edf.Events.Efix.start;
stops = m2_edf.Events.Efix.end;

is_fix = false( size(t) );

for i = 1:numel(starts)
  ind_start = find( t == starts(i) );
  ind_stop = find( t == stops(i) );
  
  is_fix(ind_start:ind_stop) = true;
end

figure(1); clf();

start_t = 300;  % s
win_size = 5;

start_t = start_t * 1e3 + t(1);
win_size = win_size * 1e3;

t_ind = t >= start_t & t < start_t + win_size;

plot( t(t_ind), pos(1, t_ind), 'r', 'linewidth', 1 ); hold on;
plot( t(t_ind), pos(2, t_ind), 'b', 'linewidth', 1 );

ys = repmat( mean(get(gca, 'ylim')), 1, sum(t_ind & is_fix) );

plot( t(t_ind & is_fix), ys, 'ko', 'markersize', 0.5 );






