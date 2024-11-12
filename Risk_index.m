% 첫 번째 CSV 파일 읽기
data1 = readtable('Price_series_final.csv'); 

% 두 번째 CSV 파일 읽기
data2 = readtable('result_AI.csv'); 

% 일별 데이터의 날짜와 값을 추출
dates1 = data1.date(2517:3522);
values1 = log(data1.GSPC(2517:3522));

% 한달 간격의 날짜와 값을 추출
dates2 = data2.date;
values2 = data2.AI;
tc = data2.tc;
tend = data2.tend;
tdist = tend./tc;

% 두번째 csv의 한달 간격의 특정값을 첫 번째 csv에 추가
combinedValues = interp1(dates2, values2, dates1, 'linear', 'extrap');
combinedValues2 = interp1(dates2, tdist, dates1, 'linear', 'extrap');

% 결합된 데이터
combinedTable = table(dates1, values1, combinedValues, combinedValues2, 'VariableNames', {'Date', 'Price', 'LPPLAI', 'tdist'});


date1 = combinedTable.Date;
values1 = combinedTable.Price;
values2 = combinedTable.LPPLAI;
values3 = combinedTable.tdist;

%writetable(Risk_index_daily, 'Risk_index_daily.csv');

%%
% 그래프를 그리기 위한 초기화
figure;
hold on;

% 가격 그래프 그리기
plot(date1, values1, 'b', 'LineWidth', 1.5);

% 위험 지수에 따른 색상 그리기
for i = 1:length(combinedValues)
    if (combinedValues(i) < 0.5 || combinedValues2(i) < 0.7)
        colorValue = [0, 1, 0]; % 초록색 설정
    elseif combinedValues(i) >= 0.5 && combinedValues2(i) >= 0.7 && combinedValues2(i) < 0.8
        colorValue = [1, 0.6, 0]; % 주황색 설정
    elseif combinedValues(i) >= 0.5 && combinedValues2(i) >= 0.8
        colorValue = [1, 0, 0]; % 빨강색 설정
    end
    plot(date1(i), values1(i), 'o', 'MarkerSize', 4, 'MarkerEdgeColor', colorValue, 'MarkerFaceColor', colorValue);
end

% 그래프 레이블링
xlabel('Date');
ylabel('Logprice');


%%
% 그래프를 그리기 위한 초기화
figure;
hold on;

% 가격 그래프 그리기
plot(date1, values1, 'b', 'LineWidth', 1.5);

% 위험 지수에 따른 색상 그리기
for i = 1:20:length(combinedValues)
    if (combinedValues(i) < 0.5 || combinedValues2(i) < 0.7)
        colorValue = [0, 1, 0]; % 초록색 설정
    elseif combinedValues(i) >= 0.5 && combinedValues2(i) >= 0.7 && combinedValues2(i) < 0.8
        colorValue = [1, 0.6, 0]; % 주황색 설정
    elseif combinedValues(i) >= 0.5 && combinedValues2(i) >= 0.8
        colorValue = [1, 0, 0]; % 빨강색 설정
    end
    plot(date1(i), values1(i), 'o', 'MarkerSize', 20, 'MarkerEdgeColor', colorValue, 'MarkerFaceColor', colorValue);
end

% 그래프 레이블링
title('Risk metric', 'FontSize', 20);
xlabel('날짜', 'FontSize', 18);
ylabel('가격', 'FontSize', 18);