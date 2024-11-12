%% price 데이터 저장
GSPC = readtable("Price/GSPC.csv");
%GSPC.Properties.VariableNames(2) = "GSPC";

%%
% 읽어올 CSV 파일이 있는 폴더 경로 설정
folderPath = "LPPL";

% 폴더 내의 파일 목록 가져오기
fileList = dir(fullfile(folderPath, '*.xlsx'));
Results = [];
for i = 1:length(fileList)
    i
    % ticker와 end_time 추출
    splitName = split(fileList(i).name, {'_', '.'});
    ticker = splitName{1};
    end_time = splitName{2};
    
    % 과거 crash
    price_origin = eval(ticker);
    date_origin = price_origin.Date;
    end_index = find(date_origin == datetime(end_time));
    date_LPPL = date_origin(1:end_index,:);
    price_LPPL = price_origin(1:end_index,:);
    [SRTPT, ~] = PREPROCESS(price_LPPL);
    
    % 시작 날짜 설정
    start_date = date_origin(SRTPT);
    start_index = SRTPT;
    Tend = end_index-start_index;

    % paramter 읽기
    filePath = fullfile(folderPath, fileList(i).name);
    parameter_data = readtable(filePath);
    current_row = parameter_data(1, :);
    new_row = {ticker, start_date, end_time, current_row.A, current_row.B, current_row.Tc, current_row.beta, current_row.C, current_row.Omega, current_row.Phi, current_row.RMSE, Tend};
    new_row_table = cell2table(new_row, 'VariableNames', {'ticker', 'start_date', 'end_time', 'A', 'B', 'Tc', 'beta', 'C', 'Omega', 'Phi', 'RMSE','tend'});
    Results = [Results; new_row_table];

end

writetable(Results, 'GSPC_Tend.csv');