table =readtable("Price_series_final.csv");

% j = 1286; %첨부터 1998-01-02까지 51번째 종목부터 100번째종목까지 
% for i = 2:2
%     i
%     data = table(1:j, [1, i]);
%     ticker = string(data.Properties.VariableNames{2});
%     end_time = data{j,1};
%     formatOut = 'yyyy-mm-dd'; 
%     end_time_str = string(datestr(end_time,formatOut));
%     outputpath = ticker+'_'+end_time_str+'.xlsx';
%     LPPLAI(data,outputpath);
% 
% end

for j = 2517:20:3562
    j
    for i = 2:2
        i
        data = table(1:j, [1, i]);
        ticker = string(data.Properties.VariableNames{2});
        end_time = data{j,1};
        formatOut = 'yyyy-mm-dd';
        end_time_str = string(datestr(end_time,formatOut));
        outputpath = ticker+'_'+end_time_str+'.xlsx';
        LPPLAI(data,outputpath);
    end
end


