spktimes = {spike_data.times};
dates = {spike_data.date};
regions = {spike_data.region};
uuid = {spike_data.uuid};
uuid_nums = arrayfun( @identity, 1:numel(uuid), 'un', 0 );

%%

pg_data = load( 'C:\Users\nick\Downloads\sorted_neural_data_social_gaze.mat' );

%%

f_regions = categorical( [dates(:), regions(:)] );
[dates_regs, ~, ic] = unique( f_regions, 'rows' );
reg_I = groupi( ic );

src_data = [];

for i = 1:numel(reg_I)  
  date = char( dates_regs(i, 1) );
  reg = char( dates_regs(i, 2) );
  
  ri = reg_I{i};
    
  spk_inds = cellfun( @(x) ceil(x * 40e3), spktimes(ri), 'un', 0 );
  spk_channel = cellfun( @(x) ones(size(x)), spk_inds, 'un', 0 );
  spk_unit_num = arrayfun( @(x, y) repmat(y, size(x{1})), spk_inds(:)', 1:numel(ri), 'un', 0 );
  % 1: channel
  % 2: spike time
  % 3: unit number
  spk_inds = horzcat( spk_inds{:} );
  spk_channel = horzcat( spk_channel{:} );
  spk_unit_num = horzcat( spk_unit_num{:} );
  
  s = struct();
  s.filename = date;
  s.region = reg;
  s.n_units = numel( ri );
  s.uuid = cat( 2, uuid_nums{ri} );
  s.spikeindices = [spk_channel; spk_inds; spk_unit_num];
  s.maxchn = ones( size(s.uuid) );
  s.validity = ones( size(s.uuid) );
  
  if ( i == 1 )
    src_data = s;
  else
    src_data(end+1) = s;
  end
end