bad_asc = 'H:\brains\free_viewing\raw\01312018\m2\L1.asc';

asc = fileread( bad_asc );
asc = strsplit( asc, '\n' );

matching_edf = Edf2Mat( 'H:\brains\free_viewing\raw\01312018\M1\K1.edf' );

% edf2asc.exe -failsafe -p H:\brains\free_viewing\raw\01312018\m2\L1_s.asc -l -s H:\brains\free_viewing\raw\01312018\m2\L1.edf
% edf2asc.exe -failsafe -l -e H:\brains\free_viewing\raw\01312018\m2\L1.edf

%%

first = asc{1};
last = asc{end-1};

first = strsplit( first, ' ' );
last = strsplit( last, ' ' );

assert( numel(first) == 4 && numel(last) == 4 );

t0 = str2double( first{1}( ~(first{1} == ' ') ) );
t1 = str2double( last{1}( ~(last{1} == ' ') ) );

assert( ~isnan(t0) && ~isnan(t1) );

N = t1 - t0 + 1;

t = nan( 1, N );
x = nan( 1, N );
y = nan( 1, N );

for i = 1:N
  current = strsplit( asc{i}, ' ' );
  assert( numel(current) == 4 );
  
  xs = current{2}(~(current{2} == ' '));
  ys = current{3}(~(current{3} == ' '));
  
  t_ = str2double( current{1}(~(current{1} == ' ')) );
  x_ = str2double( xs );
  y_ = str2double( ys );
  
  assert( ~isnan(t_) );
  
  if ( isnan(x_) )
    assert( numel(xs) == 2 && real(xs(2)) == 9 );
  end
  if ( isnan(y_) )
    assert( numel(ys) == 2 && real(xs(2)) == 9 );
  end
  
  t(i) = t_;
  x(i) = x_;
  y(i) = y_;
end

parsed_edf = struct();
parsed_edf.t = t;
parsed_edf.x = x;
parsed_edf.y = y;

%%  parse messages

asc = fileread( bad_asc );
asc = strsplit( asc, '\n' );

msgs = shared_utils.cell.containing( asc, 'MSG' );
msgs = shared_utils.cell.containing( msgs, 'RESYNCH' );

msg_t = nan( numel(msgs), 1 );
msg_info = cell( numel(msgs), 1 );

for i = 1:numel(msgs)
  
  msg = strsplit( msgs{i}, ' ' );
  
  assert( numel(msg) == 2 );
  
  msg_t_str = msg{1}(~(msg{1} == 9));
  ind = strfind( msg_t_str, 'MSG' );
  assert( numel(ind) == 1 );
  
  msg_t_str = msg_t_str( ind + numel('MSG'):end );
  
  msg_t_ = str2double( msg_t_str );
  assert( ~isnan(msg_t_) );
  
  msg_t(i) = msg_t_;  
  msg_info{i} = 'RESYNCH';
end

%%

corrected_edf = struct();
corrected_edf.Samples.time = parsed_edf.t;
corrected_edf.Samples.posX = parsed_edf.x;
corrected_edf.Samples.posY = parsed_edf.y;

corrected_edf.Events.Esacc.start = [];
corrected_edf.Events.Esacc.end = [];
corrected_edf.Events.Esacc.duration = [];

corrected_edf.Events.Messages.info = msg_info;
corrected_edf.Events.Messages.time = msg_t;

unf = '01312018_position_1.mat';

m1_m2_edf = struct();
m1_m2_edf.m1 = struct();
m1_m2_edf.m1.edf = matching_edf;
m1_m2_edf.m1.unified_filename = unf;

m1_m2_edf.m2 = struct();
m1_m2_edf.m2.edf = corrected_edf;
m1_m2_edf.m2.unified_filename = unf;

save( fullfile(bfw.get_intermediate_directory('edf'), unf), 'm1_m2_edf' );


