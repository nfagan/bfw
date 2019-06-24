function dates = active_dates_from_day_info(day_info_xls, conf)

if ( nargin < 1 || isempty(day_info_xls) )
  if ( nargin < 2 || isempty(conf) )
    conf = bfw.config.load();
  end
  
  day_info_xls = bfw_it.process_day_info_xls( bfw_it.load_day_info_xls(conf) );
end

dates = day_info_xls('date');

end