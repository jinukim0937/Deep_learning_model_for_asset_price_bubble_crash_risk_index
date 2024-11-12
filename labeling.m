%% price 데이터 저장
% 읽어올 CSV 파일이 들어 있는 폴더 경로
folder_path = 'Price';

% 폴더 내의 모든 파일 목록을 가져오기
file_list = dir(fullfile(folder_path, '*.csv'));

% 파일 목록 순회
for i = 1:length(file_list)
    file_path = fullfile(folder_path, file_list(i).name);
    [~, file_name, ~] = fileparts(file_list(i).name);
    variable_name = genvarname(file_name);
    data_raw = readtable(file_path);
    data = data_raw(:, {'Date', 'Close'});
    eval([variable_name ' = data;']); % eval 함수를 사용하여 변수에 데이터 할당
end

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

    % paramter 읽기
    filePath = fullfile(folderPath, fileList(i).name);
    parameter_data = readtable(filePath);
    
    % 실제 crash
    [~,DATE_CRASH] = PREPROCESS(price_origin);
    DATE_CRASH_datetime = datetime(DATE_CRASH,'ConvertFrom','datenum');

    parfor row = 1:500
        current_row = parameter_data(row, :);
        Tc = current_row.Tc;
        real_Tc = round(start_index + Tc);
        label = 0;
        for tc_range = -10:10
            test_Tc = real_Tc + tc_range;
            if any(DATE_CRASH_datetime == date_origin(test_Tc))
                label = 1;
            end
        end
        new_row = {ticker, start_date, end_time, current_row.A, current_row.B, current_row.Tc, current_row.beta, current_row.C, current_row.Omega, current_row.Phi, current_row.RMSE, label};
        new_row_table = cell2table(new_row, 'VariableNames', {'ticker', 'start_date', 'end_time', 'A', 'B', 'Tc', 'beta', 'C', 'Omega', 'Phi', 'RMSE', 'label'});
        Results = [Results; new_row_table];
        

    end
end

writetable(Results, 'Label_04.csv');