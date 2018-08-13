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