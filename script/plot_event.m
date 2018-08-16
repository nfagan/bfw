function plot_event(event_start, event_duration, type)


c{1} = [255 165 0]/255; % orange
c{2} = [96 128 56]/255;
c{3} = [30 144 255]/255;
% type
if type == 'm1', color = c{1}; end 
if type == 'm2', color = c{2}; end   
% if type == 'mutual', color = c{3}; end 
  


yh = 0.1*(1:length(event_start));
plot(event_start,yh,'o'), hold on
xlabel('event start')
for i = 1:length(yh)
    plot([event_start(i) event_start(i)+event_duration(i)*(1e-3)],[yh(i) yh(i)], 'LineWidth', 5, 'Color', color), hold on
end  

ylim([-2 4])