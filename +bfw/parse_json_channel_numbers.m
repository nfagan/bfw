function out = parse_json_channel_numbers( channels )

%   channels are a simple array of numbers
if ( isa(channels, 'double') )
  out = channels;
  return;
end
%   otherwise, channels are either a string like "17-32", or a mix of
%   string and number
shared_utils.assertions.assert__isa( channels, 'cell', 'channels' );
out = [];
for j = 1:numel(channels)
  chan = channels{j};    
  if ( isa(chan, 'double') )
    out(end+1) = chan;
    continue;
  end
  if ( isa(chan, 'char') )
    split_comma = cellfun( @strtrim, strsplit(chan, ','), 'un', 0 );
    
    for k = 1:numel(split_comma)
      c_chan = split_comma{k};
      
      ind = strfind( c_chan, '-' );
      err_msg = sprintf( ['Wrong format for string channel interval;' ...
        , ' expected a format like this: "17-32", but got this: "%s".'] ...
        , c_chan );

      assert( numel(ind) == 1, err_msg );

      start = str2double( c_chan(1:ind-1) );
      stop = str2double( c_chan(ind+1:end) );

      assert( ~isnan(start) && ~isnan(stop), err_msg );

      interval = start:stop;

      out(end+1:end+numel(interval)) = interval;
    end

    continue;
  end

  error( 'Unrecognized channel type "%s."', class(chan) );
end

end